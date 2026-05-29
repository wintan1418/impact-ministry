class DonationReceiptMailer < ApplicationMailer
  # Sent after a successful Stripe charge — both first-time gifts and
  # recurring renewals. Postmark transactional stream so receipts retain
  # high deliverability.
  #
  # Usage:
  #   DonationReceiptMailer.with(donation: donation).receipt.deliver_now
  def receipt
    @donation = params[:donation]
    @donor    = @donation.donor
    @host     = mail_host

    mail(
      to: @donor.email,
      subject: "Thank you for your gift — IMPACT Ministry",
      message_stream: message_stream_for(:transactional)
    )
  end

  private

  def mail_host
    ENV["APP_HOST"].presence || default_url_options[:host] || "localhost"
  end
end
