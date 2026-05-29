module Giving
  module Webhooks
    # Routes a Stripe::Event to the right handler service. Anything we don't
    # care about (e.g. analytics events) is silently acknowledged. New event
    # types go in the case below.
    class Dispatcher
      HANDLERS = {
        "checkout.session.completed"   => Giving::Webhooks::CheckoutSessionCompleted,
        "invoice.paid"                 => Giving::Webhooks::InvoicePaid,
        "customer.subscription.deleted" => Giving::Webhooks::SubscriptionDeleted,
        "payment_intent.payment_failed" => Giving::Webhooks::PaymentIntentFailed
      }.freeze

      def self.call(event)
        handler = HANDLERS[event.type]
        return :ignored unless handler

        handler.call(event)
      end
    end
  end
end
