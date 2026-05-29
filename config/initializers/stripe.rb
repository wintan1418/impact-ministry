# Stripe SDK setup.
#
# Test-mode keys are sourced from ENV in dev/test; production should use
# Rails encrypted credentials (see config/credentials.yml.enc).
#
# We don't crash on a missing key — that would make GIVING_ENABLED=false
# environments fail to boot. The service objects check at call time and
# raise a clear error if a key is needed but absent.
Rails.application.config.after_initialize do
  api_key = ENV["STRIPE_SECRET_KEY"].presence ||
            Rails.application.credentials.dig(:stripe, :secret_key)

  Stripe.api_key = api_key if api_key

  # Pin API version so an upstream SDK bump doesn't change payload shapes.
  Stripe.api_version = "2024-12-18.acacia"
end
