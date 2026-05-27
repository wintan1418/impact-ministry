# =========================================================
# IMPACT Ministry — Mail configuration
# All ActionMailer + Postmark setup lives here, not in
# config/environments/*.rb, to keep email concerns in one
# file and avoid merge conflicts between concurrent agents.
# See CLAUDE.md §3 (Mailers) and §7 (ENV vars).
# =========================================================

Rails.application.configure do
  # --- URL helpers in mailers ---
  # Mailer views call *_url and need a host. Falls back to localhost so dev
  # boots even before .env is filled in.
  default_url_options = {
    host:     ENV.fetch("APP_HOST", "localhost:3000"),
    protocol: ENV.fetch("APP_PROTOCOL", "http")
  }
  Rails.application.routes.default_url_options = default_url_options
  config.action_mailer.default_url_options = default_url_options

  # --- Postmark API token ---
  # Guarded ENV read — POSTMARK_API_TEST is Postmark's sandbox token; safe
  # to use in dev when the real token isn't set.
  config.action_mailer.postmark_settings = {
    api_token: ENV.fetch("POSTMARK_API_TOKEN", "POSTMARK_API_TEST")
  }

  # --- Delivery method per env ---
  case Rails.env
  when "production"
    config.action_mailer.delivery_method = :postmark
  when "development"
    config.action_mailer.delivery_method = :letter_opener_web
    config.action_mailer.perform_caching = false
    config.action_mailer.raise_delivery_errors = true
  else # test
    config.action_mailer.delivery_method = :test
    config.action_mailer.perform_caching = false
    config.action_mailer.raise_delivery_errors = true
  end
end

# --- Defaults applied to every mailer ---
# `from` and `reply_to` are set here so individual mailers don't have to
# repeat them. Override per-mailer if a stream needs a different identity.
ActionMailer::Base.default(
  from:     ENV.fetch("EMAIL_FROM_ADDRESS", "team@impactministry.org"),
  reply_to: ENV.fetch("EMAIL_REPLY_TO",     ENV.fetch("EMAIL_FROM_ADDRESS", "team@impactministry.org"))
)
