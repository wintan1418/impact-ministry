# frozen_string_literal: true

# Rack::Attack — throttling configuration for IMPACT Ministry.
# See CLAUDE.md §2 (Throttling) and §3 (Forms).
#
# Notes:
#   * The rack-attack railtie self-inserts the middleware; we do NOT add it manually.
#     Verify with: `bundle exec rails middleware | grep Attack`.
#   * Cache is backed by Solid Cache (the Rails 8 default `Rails.cache`).
#   * Disabled in the test environment to keep CI deterministic; runs in dev so
#     throttle behaviour can be smoke-tested locally.

# Run everywhere except in test (dev + production both throttle).
Rack::Attack.enabled = !Rails.env.test?

# Use the configured Rails cache (Solid Cache in this app).
Rack::Attack.cache.store = Rails.cache

# --- Safelists ---------------------------------------------------------------
# Localhost should never be throttled — dev, CI, internal healthchecks.
Rack::Attack.safelist_ip("127.0.0.1")
Rack::Attack.safelist_ip("::1")

# --- Throttles ---------------------------------------------------------------
# Public form endpoints — 5 requests/second/IP across all of them.
# Per CLAUDE.md §3: every public form is Turnstile-protected and Rack::Attack-throttled.
PUBLIC_FORM_PATHS = %w[
  /subscribe
  /prayer_requests
  /pray
  /testimonies
  /testify
  /contact
  /feedback_messages
  /partnerships
  /partner
  /give
].freeze

Rack::Attack.throttle("public_forms", limit: 5, period: 1) do |req|
  req.ip if req.post? && PUBLIC_FORM_PATHS.include?(req.path)
end

# Sign-in: 10 attempts per IP per minute.
Rack::Attack.throttle("sign_in", limit: 10, period: 60) do |req|
  req.ip if req.post? && req.path == "/session"
end

# Password reset requests: 5 per IP per hour.
Rack::Attack.throttle("password_reset", limit: 5, period: 3600) do |req|
  req.ip if req.post? && req.path == "/passwords"
end

# --- Blocked response --------------------------------------------------------
# 429 with a friendly body. JSON for API-style clients, plain text otherwise.
Rack::Attack.blocklisted_responder = ->(_request) {
  # noop — we don't use blocklists yet; throttles use throttled_responder.
  [ 429, { "Content-Type" => "text/plain" }, [ "Slow down." ] ]
}

Rack::Attack.throttled_responder = lambda do |request|
  accepts_json = request.get_header("HTTP_ACCEPT").to_s.include?("application/json")

  if accepts_json
    [
      429,
      { "Content-Type" => "application/json" },
      [ { error: "Slow down." }.to_json ]
    ]
  else
    [
      429,
      { "Content-Type" => "text/plain" },
      [ "Slow down." ]
    ]
  end
end
