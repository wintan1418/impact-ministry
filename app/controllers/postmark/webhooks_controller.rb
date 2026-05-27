# Receives Postmark webhook callbacks (Open, Click, Bounce,
# SpamComplaint, Delivery, etc.).
#
# Behaviour:
#   - Always returns 200 — Postmark retries on non-2xx, which would
#     create duplicate side-effects.
#   - Verifies the request via HTTP Basic auth if
#     POSTMARK_WEBHOOK_USERNAME / POSTMARK_WEBHOOK_PASSWORD are set
#     (Postmark supports basic-auth on webhook URLs — see their docs).
#     If not configured, accepts the request and logs a warning so dev
#     traffic still works.
#   - Defers all real processing to ProcessPostmarkWebhookJob so the
#     controller stays fast — Postmark times out at 10 seconds.
#
# Route: POST /postmark/webhooks  (see config/routes.rb).
class Postmark::WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  skip_before_action :resume_session, raise: false

  before_action :authenticate_postmark!

  def create
    payload = params.except(:controller, :action, :webhook).to_unsafe_h
    ProcessPostmarkWebhookJob.perform_later(payload: payload)
    head :ok
  end

  private

  def authenticate_postmark!
    expected_user = ENV["POSTMARK_WEBHOOK_USERNAME"].presence
    expected_pass = ENV["POSTMARK_WEBHOOK_PASSWORD"].presence

    unless expected_user && expected_pass
      Rails.logger.warn(
        "[Postmark::WebhooksController] POSTMARK_WEBHOOK_USERNAME / " \
        "POSTMARK_WEBHOOK_PASSWORD not set — accepting webhook without auth."
      )
      return
    end

    authenticate_or_request_with_http_basic("Postmark") do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user.to_s, expected_user) &
        ActiveSupport::SecurityUtils.secure_compare(pass.to_s, expected_pass)
    end
  end
end
