module Giving
  # Builds a Stripe Checkout Session for either a one-time gift or a monthly
  # recurring donation. Returns a Result wrapping either the Stripe URL or
  # an error message for the form to surface.
  #
  # Why Checkout (not Elements): no PCI scope on our side, Stripe hosts the
  # card form, and the customer comes back to /give/thanks. CLAUDE.md §5
  # specifies this flow.
  class CreateCheckoutSession
    AMOUNT_RANGE = (100..1_000_000) # $1 — $10,000 per checkout

    def self.call(**kwargs) = new(**kwargs).call

    def initialize(amount_cents:, frequency:, designation:, email:, name: nil, success_url:, cancel_url:)
      @amount_cents = amount_cents.to_i
      @frequency    = frequency.to_s
      @designation  = designation.to_s
      @email        = email.to_s.strip.downcase
      @name         = name.to_s.strip.presence
      @success_url  = success_url
      @cancel_url   = cancel_url
    end

    def call
      validation = validate
      return failure(validation) if validation

      session = Stripe::Checkout::Session.create(session_params)
      Giving::Result.new(success: true, value: session)
    rescue Stripe::StripeError => e
      Rails.logger.error("[Giving::CreateCheckoutSession] #{e.class}: #{e.message}")
      failure("We couldn't reach Stripe. Please try again in a moment.")
    end

    private

    attr_reader :amount_cents, :frequency, :designation, :email, :name, :success_url, :cancel_url

    def validate
      return "Please enter a valid email so we can send your receipt." if email.blank? || !email.include?("@")
      return "Please choose a gift amount." unless AMOUNT_RANGE.cover?(amount_cents)
      return "Please choose a frequency."   unless Donation::FREQUENCIES.include?(frequency)
      return "Please choose a designation." unless Donation::DESIGNATIONS.include?(designation)

      nil
    end

    def session_params
      base = {
        mode: stripe_mode,
        customer_email: email,
        success_url: success_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: cancel_url,
        metadata: metadata,
        line_items: [ line_item ]
      }
      base[:subscription_data] = { metadata: metadata } if recurring?
      base[:payment_intent_data] = { metadata: metadata } unless recurring?
      base
    end

    def stripe_mode
      recurring? ? "subscription" : "payment"
    end

    def recurring?
      frequency == "monthly"
    end

    def line_item
      {
        quantity: 1,
        price_data: {
          currency: "usd",
          unit_amount: amount_cents,
          product_data: {
            name: product_name,
            description: "IMPACT Ministry · #{Donation::DESIGNATION_LABELS.fetch(designation)}"
          },
          (recurring? ? :recurring : nil) => (recurring? ? { interval: "month" } : nil)
        }.compact
      }
    end

    def product_name
      if recurring?
        "Monthly partnership — #{Donation::DESIGNATION_LABELS.fetch(designation)}"
      else
        "One-time gift — #{Donation::DESIGNATION_LABELS.fetch(designation)}"
      end
    end

    def metadata
      {
        designation: designation,
        frequency: frequency,
        donor_name: name.to_s,
        donor_email: email
      }
    end

    def failure(message)
      Giving::Result.new(success: false, error: message)
    end
  end
end
