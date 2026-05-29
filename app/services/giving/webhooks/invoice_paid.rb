module Giving
  module Webhooks
    # Recurring renewal — Stripe charges the saved card each month and fires
    # invoice.paid. Creates a new Donation row for the month so the donor's
    # history stays accurate. Skips the very first invoice (checkout_session
    # already handled it).
    class InvoicePaid
      def self.call(event) = new(event).call

      def initialize(event)
        @event   = event
        @invoice = event.data.object
      end

      def call
        return :ignored if @invoice.subscription.blank?
        # Stripe sends an invoice.paid for the FIRST subscription charge
        # immediately after checkout.session.completed; skip that one to
        # avoid double-counting.
        return :ignored if billing_reason_is_first_create?

        donor = Donor.find_by(stripe_customer_id: @invoice.customer)
        return :ignored if donor.nil?

        donation = Donation.find_or_initialize_by(stripe_payment_intent_id: @invoice.payment_intent)
        donation.donor                  = donor
        donation.amount_cents           = @invoice.amount_paid.to_i
        donation.currency               = (@invoice.currency || "usd").downcase
        donation.frequency              = "monthly"
        donation.designation            = designation_from(donor)
        donation.stripe_subscription_id = @invoice.subscription
        donation.status                 = "succeeded"
        donation.donated_at             ||= Time.current
        donation.save!

        Giving::DonationReceiptJob.perform_later(donation.id)
        donation
      end

      private

      def billing_reason_is_first_create?
        @invoice.billing_reason.to_s == "subscription_create"
      end

      def designation_from(donor)
        # Prefer the designation from the donor's most recent recurring donation,
        # falling back to "general" if none recorded.
        donor.donations.where.not(designation: nil).recent_first.first&.designation || "general"
      end
    end
  end
end
