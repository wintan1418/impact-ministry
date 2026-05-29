# Background processor for Stripe webhook events. Re-parses the raw payload
# (and re-verifies the signature when present) so handlers always operate on
# a fully-typed Stripe::Event. Idempotent: a ProcessedStripeEvent row is
# inserted *before* dispatch; duplicate deliveries no-op.
class StripeWebhookJob < ApplicationJob
  queue_as :stripe_webhooks

  retry_on Stripe::APIConnectionError, wait: :polynomially_longer, attempts: 5
  retry_on Stripe::APIError,           wait: :polynomially_longer, attempts: 3

  def perform(payload:, signature:, event_id: nil, event_type: nil)
    event = build_event(payload, signature, event_id, event_type)
    return if event.nil?

    # Idempotency guard — unique index on stripe_event_id makes the
    # second insert race-safe even under concurrent delivery.
    ProcessedStripeEvent.create!(
      stripe_event_id: event.id,
      event_type: event.type,
      processed_at: Time.current
    )

    Giving::Webhooks::Dispatcher.call(event)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
    # RecordInvalid catches the model-level uniqueness validation; RecordNotUnique
    # catches the DB-level unique index race condition. Either way, this event
    # has already been processed.
    Rails.logger.info("[StripeWebhookJob] already processed event #{event_id || 'unknown'} (#{e.class}), skipping.")
  end

  private

  def build_event(payload, signature, event_id, event_type)
    secret = ENV["STRIPE_WEBHOOK_SECRET"].to_s
    if secret.present? && signature.present?
      Stripe::Webhook.construct_event(payload, signature, secret)
    else
      Stripe::Event.construct_from(JSON.parse(payload))
    end
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.warn("[StripeWebhookJob] dropped: #{e.class}: #{e.message}")
    nil
  end
end
