module Giving
  module Webhooks
    # Card declined, expired, etc. Marks the matching donation as failed if
    # we already have a row; otherwise no-op.
    class PaymentIntentFailed
      def self.call(event) = new(event).call

      def initialize(event)
        @event = event
        @intent = event.data.object
      end

      def call
        donation = Donation.find_by(stripe_payment_intent_id: @intent.id)
        donation&.update!(status: "failed")
        donation || :ignored
      end
    end
  end
end
