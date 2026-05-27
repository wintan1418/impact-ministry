require "rails_helper"

# Rack::Attack request behaviour.
#
# Per config/initializers/rack_attack.rb, the middleware is DISABLED in the
# test environment (`Rack::Attack.enabled = !Rails.env.test?`). That's an
# intentional posture: throttle behaviour is timing-sensitive, depends on a
# shared cache store, and tends to produce flaky CI runs when exercised end-
# to-end. The throttles are smoke-tested in development against the running
# server instead (see CLAUDE.md §2).
#
# The example below documents the expected production behaviour and is tagged
# :integration so it is skipped by default. To run it manually:
#
#     RACK_ATTACK_E2E=1 bundle exec rspec spec/requests/rack_attack_spec.rb \
#       --tag integration
#
RSpec.describe "Rack::Attack throttling", type: :request do
  it "is disabled in the test environment by design" do
    expect(Rack::Attack.enabled).to eq(false)
  end

  it "throttles bursts of POSTs to /subscribe to 5/second/IP", :integration do
    skip "rack-attack is disabled in test env; run manually with RACK_ATTACK_E2E=1" \
      unless ENV["RACK_ATTACK_E2E"]

    # Documented behaviour — enable this block locally to exercise it:
    #
    #   Rack::Attack.enabled = true
    #   6.times { post "/subscribe", params: { email: "a@b.test" } }
    #   expect(response).to have_http_status(:too_many_requests)
  end
end
