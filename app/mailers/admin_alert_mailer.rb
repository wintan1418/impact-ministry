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
end
