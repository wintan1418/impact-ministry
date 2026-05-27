# Delivers a single devotional email to a single subscriber and records
# the send as a DevotionalDelivery row.
#
# Enqueued in bulk by DevotionalDispatchJob (one job per active
# subscriber). Each job is independently retryable on transient network
# errors so a single Postmark blip doesn't burn the whole broadcast.
#
# Idempotency:
#   The DevotionalDelivery row is created BEFORE the mail is sent, with
#   a unique (devotional_id, email_subscriber_id) index. If a duplicate
#   row insert raises, we short-circuit — another job already delivered.
#
# See CLAUDE.md §3 (Background jobs) and §5 (dispatch flow).
class DevotionalDeliveryJob < ApplicationJob
  queue_as :mailers

  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 3
  retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 3

  if defined?(Postmark::ApiInputError)
    retry_on Postmark::ApiInputError, wait: :polynomially_longer, attempts: 3
  end

  discard_on ActiveRecord::RecordNotFound

  def perform(devotional_id:, subscriber_id:)
    devotional = Devotional.find(devotional_id)
    subscriber = EmailSubscriber.find(subscriber_id)

    return unless subscriber.active?

    delivery = create_delivery(devotional, subscriber)
    return if delivery.nil? # already-sent short-circuit

    mail = DevotionalMailer.with(devotional: devotional, subscriber: subscriber).daily
    mail.deliver_now

    message_id = extract_postmark_message_id(mail)
    delivery.update(postmark_message_id: message_id) if message_id.present?
  end

  private

  # Returns the new DevotionalDelivery row, or nil when the (devotional,
  # subscriber) pair already has one — i.e. another job beat us to it.
  def create_delivery(devotional, subscriber)
    DevotionalDelivery.create!(
      devotional: devotional,
      email_subscriber: subscriber,
      sent_at: Time.current
    )
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    Rails.logger.info(
      "[DevotionalDeliveryJob] Skipping duplicate send for devotional " \
      "##{devotional.id} / subscriber ##{subscriber.id}."
    )
    nil
  end

  # Postmark returns a MessageID per send. The postmark-rails gem stores
  # it on the Mail::Message itself under `message_id` (the standard RFC
  # field). Different versions also stash it in delivery_handler /
  # postmark_response — try both gently.
  def extract_postmark_message_id(mail)
    response = mail.delivery_method.try(:response) if mail.delivery_method.respond_to?(:response)
    return response["MessageID"] if response.is_a?(Hash) && response["MessageID"].present?

    mid = mail.message_id.to_s
    mid.presence
  rescue StandardError => e
    Rails.logger.warn("[DevotionalDeliveryJob] Could not extract Postmark MessageID: #{e.class}")
    nil
  end
end
