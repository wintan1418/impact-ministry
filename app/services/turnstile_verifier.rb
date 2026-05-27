# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

# TurnstileVerifier
#
# Verifies a Cloudflare Turnstile token against the siteverify endpoint.
#
# Usage:
#   result = TurnstileVerifier.call(token: params["cf-turnstile-response"],
#                                   remote_ip: request.remote_ip)
#   if result.success?
#     # continue
#   else
#     # result.errors => array of Turnstile error codes (or ["network_error"])
#   end
#
# Test environment short-circuits: any token returns success EXCEPT the literal
# string "FORCE_FAIL", which yields a failure result. This keeps unit specs
# deterministic and lets us exercise the failure branch without HTTP stubs.
#
# In dev/prod the Cloudflare test keys configured in .env.example always pass,
# so this service is safe to exercise against live Cloudflare during local dev.
class TurnstileVerifier
  SITEVERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"
  TIMEOUT_SECONDS = 5

  Result = Struct.new(:success, :errors, keyword_init: true) do
    def success?
      success == true
    end
  end

  def self.call(token:, remote_ip: nil)
    new.call(token: token, remote_ip: remote_ip)
  end

  def call(token:, remote_ip: nil)
    return test_env_result(token) if Rails.env.test?

    verify_with_cloudflare(token: token, remote_ip: remote_ip)
  end

  private

  def test_env_result(token)
    if token == "FORCE_FAIL"
      Result.new(success: false, errors: [ "forced-failure" ])
    else
      Result.new(success: true, errors: [])
    end
  end

  def verify_with_cloudflare(token:, remote_ip:)
    uri = URI.parse(SITEVERIFY_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT_SECONDS
    http.read_timeout = TIMEOUT_SECONDS

    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(
      "secret" => ENV["TURNSTILE_SECRET_KEY"].to_s,
      "response" => token.to_s,
      "remoteip" => remote_ip.to_s
    )

    response = http.request(request)
    body = JSON.parse(response.body.to_s)

    if body["success"] == true
      Result.new(success: true, errors: [])
    else
      Result.new(success: false, errors: Array(body["error-codes"]))
    end
  rescue StandardError => e
    Rails.logger.warn("[TurnstileVerifier] network error: #{e.class}: #{e.message}")
    Result.new(success: false, errors: [ "network_error" ])
  end
end
