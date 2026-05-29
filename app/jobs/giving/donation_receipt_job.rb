module Giving
  # Sends the donor a thank-you / receipt email. Marks receipt_sent_at so
  # we don't re-send on subsequent webhook replays.
  class DonationReceiptJob < ApplicationJob
    queue_as :mailers

    def perform(donation_id)
      donation = Donation.find_by(id: donation_id)
      return if donation.nil?
      return if donation.receipt_sent_at.present?
      return unless donation.status == "succeeded"

      DonationReceiptMailer.with(donation: donation).receipt.deliver_now
      donation.update!(receipt_sent_at: Time.current)
    end
  end
end
