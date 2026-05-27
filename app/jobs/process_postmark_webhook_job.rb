# Asynchronously processes a Postmark webhook payload. Branches on
# RecordType:
#
#   Open           -> mark DevotionalDelivery#open!
#   Click          -> mark DevotionalDelivery#click!
#   Bounce         -> unsubscribe the recipient
#   SpamComplaint  -> unsubscribe the recipient
#   Delivery       -> log + ignore (we already know we sent it)
#   *              -> log + ignore (forward-compatible)
#
# Idempotent: open!/click! short-circuit when the timestamps are already
# set. unsubscribe! is safe to re-run on an already-unsubscribed row.
class ProcessPostmarkWebhookJob < ApplicationJob
  queue_as :default

  def perform(payload:)
    payload = payload.with_indifferent_access
    record_type = payload[:RecordType].to_s

    case record_type
    when "Open"          then handle_open(payload)
    when "Click"         then handle_click(payload)
    when "Bounce"        then handle_bounce(payload)
    when "SpamComplaint" then handle_spam_complaint(payload)
    when "Delivery"
      Rails.logger.info("[ProcessPostmarkWebhookJob] Delivery confirmed for MessageID=#{payload[:MessageID]}")
    else
      Rails.logger.info("[ProcessPostmarkWebhookJob] Ignoring RecordType=#{record_type.inspect}")
    end
  end

  private

  def handle_open(payload)
    delivery = find_delivery(payload[:MessageID])
    return log_missing("Open", payload[:MessageID]) unless delivery

    delivery.open!(at: parse_time(payload[:ReceivedAt]))
  end

  def handle_click(payload)
    delivery = find_delivery(payload[:MessageID])
    return log_missing("Click", payload[:MessageID]) unless delivery

    delivery.click!(at: parse_time(payload[:ReceivedAt]))
  end

  def handle_bounce(payload)
    unsubscribe_by_email(payload[:Email], reason: "Bounce (#{payload[:Type]})")
  end

  def handle_spam_complaint(payload)
    unsubscribe_by_email(payload[:Email], reason: "SpamComplaint")
  end

  def find_delivery(message_id)
    return nil if message_id.blank?

    DevotionalDelivery.find_by(postmark_message_id: message_id)
  end

  def unsubscribe_by_email(email, reason:)
    return if email.blank?

    subscriber = EmailSubscriber.where("lower(email) = ?", email.to_s.strip.downcase).first
    unless subscriber
      Rails.logger.info("[ProcessPostmarkWebhookJob] #{reason} for unknown email #{email}")
      return
    end

    return unless subscriber.active?

    subscriber.unsubscribe!
    Rails.logger.info("[ProcessPostmarkWebhookJob] Unsubscribed #{email} (#{reason})")
  end

  def parse_time(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    Time.current
  end

  def log_missing(kind, message_id)
    Rails.logger.info(
      "[ProcessPostmarkWebhookJob] #{kind} event for unknown MessageID=#{message_id.inspect} — ignoring."
    )
  end
end
