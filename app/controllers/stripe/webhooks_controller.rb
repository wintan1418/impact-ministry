# Receives Stripe webhook callbacks.
#
# Behaviour mirrors Postmark::WebhooksController:
#   - Verifies the signing secret (`STRIPE_WEBHOOK_SECRET`); rejects with
#     400 on a bad signature so a misconfigured forwarder shows up fast.
#   - Always returns 200 on a valid event (Stripe retries on non-2xx),
#     handing the payload off to StripeWebhookJob on the
#     :stripe_webhooks queue for idempotent processing.
#   - Skips CSRF + session resume — Stripe is unauthenticated and the
#     CSRF token isn't applicable to webhook callbacks.
#
# Route: POST /stripe/webhooks (see config/routes.rb).
class Stripe::WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  skip_before_action :resume_session, raise: false

  def create
    payload    = request.body.read
    signature  = request.env["HTTP_STRIPE_SIGNATURE"].to_s
    secret     = ENV["STRIPE_WEBHOOK_SECRET"].to_s

    if secret.blank?
      Rails.logger.warn("[Stripe::WebhooksController] STRIPE_WEBHOOK_SECRET not set — accepting event without verification (dev only).")
      event = JSON.parse(payload, symbolize_names: true)
      StripeWebhookJob.perform_later(payload: payload, signature: nil)
      return head :ok
    end

    begin
      event = ::Stripe::Webhook.construct_event(payload, signature, secret)
    rescue JSON::ParserError, ::Stripe::SignatureVerificationError => e
      Rails.logger.warn("[Stripe::WebhooksController] rejected: #{e.class}: #{e.message}")
      return head :bad_request
    end

    StripeWebhookJob.perform_later(payload: payload, signature: signature, event_id: event.id, event_type: event.type)
    head :ok
  end
end
