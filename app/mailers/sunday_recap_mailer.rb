class SundayRecapMailer < ApplicationMailer
  # The Sunday recap email — visually distinct from the daily devotional
  # send. Magazine-style layout, up to seven devotionals from the past
  # seven days, one quiet footer pointing at tomorrow's word.
  #
  # We opt out of the shared `mailer` layout so the recap can own its
  # own chrome (header, dividers, footer) and read as a distinct piece
  # in the inbox — not a clone of the daily send.
  layout false
  #
  # Sent via the Postmark `broadcast` stream so transactional deliverability
  # (welcomes, receipts) is not downgraded by bulk volume. See
  # ApplicationMailer#message_stream_for and CLAUDE.md §5.
  #
  # Usage:
  #   SundayRecapMailer.with(
  #     subscriber: sub,
  #     devotionals: devos,
  #     week_ending: Date.current
  #   ).recap.deliver_now
  def recap
    @subscriber  = params[:subscriber]
    @devotionals = params[:devotionals]
    @week_ending = params[:week_ending]
    @host        = mail_host
    @unsubscribe_url = unsubscribe_url(token: @subscriber.token, host: @host)
    @tomorrow = Devotional.published.find_by(scheduled_for: @week_ending + 1.day)

    mail(
      to: @subscriber.email,
      subject: "This week, in a quiet word — IMPACT Ministry recap for #{@week_ending.strftime('%B %-d')}",
      message_stream: message_stream_for(:broadcast)
    )
  end

  private

  def mail_host
    ENV["APP_HOST"].presence || default_url_options[:host] || "localhost"
  end
end
