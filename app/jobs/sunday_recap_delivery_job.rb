# Delivers a single Sunday recap email to a single subscriber.
#
# Enqueued in bulk by SundayRecapDispatchJob (one job per active
# subscriber). Each job is independently retryable on transient network
# errors so a Postmark blip doesn't burn the whole broadcast.
#
# No per-email persistence: the Sunday recap is a single magazine-style
# email per week, not a per-devotional send, so there is no recap-row
# table. Engagement (open/click) lands on the EmailSubscriber via the
# Postmark webhook stream like any other broadcast.
#
# See CLAUDE.md §3 (Background jobs) and §5 (Sunday recap email).
class SundayRecapDeliveryJob < ApplicationJob
  queue_as :mailers

  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 3
  retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 3

  if defined?(Postmark::ApiInputError)
    retry_on Postmark::ApiInputError, wait: :polynomially_longer, attempts: 3
  end

  discard_on ActiveRecord::RecordNotFound

  def perform(subscriber_id:, week_ending:)
    subscriber = EmailSubscriber.find(subscriber_id)
    return unless subscriber.active?

    week_ending_date = Date.parse(week_ending)
    window_start = week_ending_date - 6.days

    devotionals = Devotional
      .published
      .where(scheduled_for: window_start..week_ending_date)
      .recent_first

    return if devotionals.empty?

    mail = SundayRecapMailer.with(
      subscriber: subscriber,
      devotionals: devotionals,
      week_ending: week_ending_date
    ).recap

    mail.deliver_now

    message_id = extract_postmark_message_id(mail)
    if message_id.present?
      Rails.logger.info(
        "[SundayRecapDeliveryJob] sent recap to subscriber ##{subscriber.id} " \
        "(message_id=#{message_id})."
      )
    end
  end

  private

  # Postmark returns a MessageID per send. Different versions of
  # postmark-rails stash it in delivery_handler / postmark_response — try
  # both gently. Mirrors DevotionalDeliveryJob#extract_postmark_message_id.
  def extract_postmark_message_id(mail)
    response = mail.delivery_method.try(:response) if mail.delivery_method.respond_to?(:response)
    return response["MessageID"] if response.is_a?(Hash) && response["MessageID"].present?

    mid = mail.message_id.to_s
    mid.presence
  rescue StandardError => e
    Rails.logger.warn("[SundayRecapDeliveryJob] Could not extract Postmark MessageID: #{e.class}")
    nil
  end
end
