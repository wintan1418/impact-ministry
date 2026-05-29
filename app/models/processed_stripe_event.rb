# Idempotency guard for Stripe webhooks. We record every event_id we have
# already finished processing; the webhook job upserts here before doing
# work and skips on conflict. Same pattern Stripe themselves recommend.
class ProcessedStripeEvent < ApplicationRecord
  validates :stripe_event_id, presence: true, uniqueness: true
  validates :event_type, presence: true
end
