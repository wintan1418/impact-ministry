module Giving
  # Opens Stripe's hosted Billing Portal so a recurring donor can update
  # their card, change the amount, or cancel — without writing any of that
  # UI ourselves.
  class CreateBillingPortalSession
    def self.call(**kwargs) = new(**kwargs).call

    def initialize(donor:, return_url:)
      @donor = donor
      @return_url = return_url
    end

    def call
      return failure("This donor doesn't have a Stripe customer yet.") if @donor.stripe_customer_id.blank?

      session = Stripe::BillingPortal::Session.create(
        customer: @donor.stripe_customer_id,
        return_url: @return_url
      )
      Giving::Result.new(success: true, value: session)
    rescue Stripe::StripeError => e
      Rails.logger.error("[Giving::CreateBillingPortalSession] #{e.class}: #{e.message}")
      failure("We couldn't open the billing portal. Please try again in a moment.")
    end

    private

    def failure(msg) = Giving::Result.new(success: false, error: msg)
  end
end
