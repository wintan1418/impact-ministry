class SubscriberMailer < ApplicationMailer
  # Welcome the new subscriber. Sent via the transactional ("outbound") Postmark
  # stream so deliverability isn't downgraded by bulk traffic.
  #
  # Usage:
  #   SubscriberMailer.with(subscriber: sub).welcome.deliver_later
  def welcome
    @subscriber = params[:subscriber]
    @unsubscribe_url = confirm_unsubscribe_url(token: @subscriber.token, host: mail_host)

    mail(
      to: @subscriber.email,
      subject: "Welcome to IMPACT Ministry",
      message_stream: message_stream_for(:transactional)
    )
  end

  private

  def mail_host
    ENV["APP_HOST"].presence || default_url_options[:host] || "localhost"
  end
end
