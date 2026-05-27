source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Password hashing for Rails 8 native authentication
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# === IMPACT Ministry stack additions (CLAUDE.md §2) ===

# Authorization
gem "pundit", "~> 2.4"

# Slugs
gem "friendly_id", "~> 5.5"

# Postgres full-text + trigram search
gem "pg_search", "~> 2.3"

# Admin CMS at /admin — github main supports Rails 8 + Propshaft + Hotwire
gem "activeadmin", github: "activeadmin/activeadmin", branch: "master"

# Transactional + broadcast email via Postmark
gem "postmark-rails", "~> 0.22"

# Payments (Phase 3+; ENV-gated via GIVING_ENABLED)
gem "stripe", "~> 13.0"

# Cloudflare R2 via S3-compatible API
gem "aws-sdk-s3", "~> 1.180", require: false

# In-app + email notification orchestration
gem "noticed", "~> 2.6"

# Request throttling
gem "rack-attack", "~> 6.7"

# Components with logic — used sparingly (see CLAUDE.md §3)
# 4.9+ closes GHSA-7f3r-gwc9-2995 and GHSA-hg3h-g7xc-f7vp.
gem "view_component", "~> 4.9"

# Local ENV loading; secrets in encrypted credentials in prod
gem "dotenv-rails"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Testing
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.5"
end

group :test do
  gem "shoulda-matchers", "~> 6.4"
  gem "capybara"
  gem "selenium-webdriver"
  gem "rails-controller-testing"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Letter Opener for email previews in dev
  gem "letter_opener_web", "~> 3.0"
end
