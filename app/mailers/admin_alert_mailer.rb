# Operational alerts to ENV["ADMIN_NOTIFICATION_EMAIL"]. These are
# always sent on the transactional ("outbound") Postmark stream — bulk
# downgrades on the broadcast stream would be the worst place for an
# alert to get stuck.
class AdminAlertMailer < ApplicationMailer
  # Sent by FailedDispatchAlertJob at 06:00 when no devotional has been
  # published for today.
  #
  # Usage:
  #   AdminAlertMailer.with(date: Date.current).missing_devotional.deliver_now
  def missing_devotional
    @date     = params[:date] || Date.current
    @host     = ENV["APP_HOST"].presence || default_url_options[:host] || "localhost"
    @admin_url = "#{ENV.fetch('APP_PROTOCOL', 'https')}://#{@host}/admin/devotionals"

    recipient = ENV.fetch("ADMIN_NOTIFICATION_EMAIL", "team@impactministry.org")

    mail(
      to: recipient,
      subject: "No devotional published today — IMPACT",
      message_stream: message_stream_for(:transactional)
    )
  end

  # Sent by FeedbackNotificationJob when a new contact-form submission
  # lands. Editors get a plaintext-friendly alert with the writer's note +
  # a deep link to the admin record so they can reply from their own inbox.
  #
  # Usage:
  #   AdminAlertMailer.with(feedback_id: message.id).new_feedback.deliver_now
  def new_feedback
    @feedback  = FeedbackMessage.find(params[:feedback_id])
    @host      = ENV["APP_HOST"].presence || default_url_options[:host] || "localhost"
    @admin_url = "#{ENV.fetch('APP_PROTOCOL', 'https')}://#{@host}/admin/feedback_messages/#{@feedback.id}"

    recipient = ENV.fetch("ADMIN_NOTIFICATION_EMAIL", "team@impactministry.org")

    mail(
      to: recipient,
      subject: "New contact: #{@feedback.kind} — #{@feedback.name}",
      message_stream: message_stream_for(:transactional)
    )
  end

  # Sent by PartnershipNotificationJob when a new /partner intake lands.
  # Editors get a plaintext-friendly alert with the org's note + a deep
  # link to the admin record so they can triage from their own inbox.
  #
  # Usage:
  #   AdminAlertMailer.with(partnership_id: p.id).new_partnership.deliver_now
  def new_partnership
    @partnership = Partnership.find(params[:partnership_id])
    @host        = ENV["APP_HOST"].presence || default_url_options[:host] || "localhost"
    @admin_url   = "#{ENV.fetch('APP_PROTOCOL', 'https')}://#{@host}/admin/partnerships/#{@partnership.id}"

    recipient = ENV.fetch("ADMIN_NOTIFICATION_EMAIL", "team@impactministry.org")

    mail(
      to: recipient,
      subject: "New partnership: #{@partnership.kind_label} — #{@partnership.organization_name}",
      message_stream: message_stream_for(:transactional)
    )
  end
end
