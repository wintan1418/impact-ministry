module Giving
  module Webhooks
    # Fires when a customer completes Stripe Checkout — both for one-time
    # gifts and the first payment of a recurring subscription. Upserts the
    # Donor by email + stripe_customer_id, then creates the Donation row.
    # Idempotent: keyed on the checkout session id.
    class CheckoutSessionCompleted
      def self.call(event) = new(event).call

      def initialize(event)
        @event   = event
        @session = event.data.object
      end

      def call
        return :ignored if @session.payment_status.to_s == "unpaid"

        donor = upsert_donor
        donation = Donation.find_or_initialize_by(stripe_checkout_session_id: @session.id)

        donation.donor               = donor
        donation.amount_cents        = @session.amount_total.to_i
        donation.currency            = (@session.currency || "usd").downcase
        donation.frequency           = recurring? ? "monthly" : "once"
        donation.designation         = designation
        donation.stripe_payment_intent_id = @session.payment_intent unless recurring?
        donation.stripe_subscription_id   = @session.subscription if recurring?
        donation.status              = "succeeded"
        donation.donated_at          ||= Time.current
        donation.save!

        Giving::DonationReceiptJob.perform_later(donation.id)
        donation
      end

      private

      def recurring?
        @session.mode.to_s == "subscription"
      end

      def designation
        d = @session.metadata&.[]("designation")
        Donation::DESIGNATIONS.include?(d) ? d : "general"
      end

      def upsert_donor
        email = (@session.customer_email || @session.metadata&.[]("donor_email") || "").downcase.strip
        name  = @session.metadata&.[]("donor_name").to_s.strip
        stripe_customer_id = @session.customer

        donor = Donor.find_by(stripe_customer_id: stripe_customer_id) if stripe_customer_id.present?
        donor ||= Donor.find_by(email: email) if email.present?
        donor ||= Donor.new(email: email)

        donor.stripe_customer_id = stripe_customer_id if stripe_customer_id.present?
        donor.name = name if name.present? && donor.name.blank?
        # Best-effort link to a User if one exists with the same email.
        donor.user ||= User.find_by("LOWER(email_address) = ?", email) if email.present?
        donor.save!
        donor
      end
    end
  end
end
