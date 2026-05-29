module Giving
  module Webhooks
    # The donor canceled their recurring gift (via Billing Portal or admin
    # action). Mark any pending donations on this subscription as canceled.
    class SubscriptionDeleted
      def self.call(event) = new(event).call

      def initialize(event)
        @event = event
        @subscription = event.data.object
      end

      def call
        Donation.where(stripe_subscription_id: @subscription.id, status: "pending")
                .update_all(status: "canceled", updated_at: Time.current)
        :ok
      end
    end
  end
end
