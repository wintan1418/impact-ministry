class DevotionalMailer < ApplicationMailer
  # The daily devotional email — sent via the Postmark `broadcast` stream
  # so deliverability of transactional mail (welcomes, receipts) is not
  # downgraded by bulk volume. See ApplicationMailer#message_stream_for.
  #
  # Usage:
  #   DevotionalMailer.with(devotional: dev, subscriber: sub).daily.deliver_now
  def daily
    @devotional     = params[:devotional]
    @subscriber     = params[:subscriber]
    @host           = mail_host
    @devotional_url = devotional_url(@devotional.slug, host: @host)
    @unsubscribe_url = unsubscribe_url(token: @subscriber.token, host: @host)
    @tomorrow        = @devotional.tomorrow

    mail(
      to: @subscriber.email,
      subject: "#{@devotional.title} — IMPACT Ministry",
      message_stream: message_stream_for(:broadcast)
    )
  end

  private

  def mail_host
    ENV["APP_HOST"].presence || default_url_options[:host] || "localhost"
  end
end
