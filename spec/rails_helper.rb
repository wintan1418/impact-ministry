# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'shoulda/matchers'
require 'active_job/test_helper'

# Load support files
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# Capybara configuration: rack_test by default, headless Chrome for `js: true`.
Capybara.default_driver = :rack_test
# Allow `fill_in "Email address"` to match inputs that use aria-label
# (we don't always render a visible <label>, e.g. compact email captures).
Capybara.enable_aria_label = true

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # FactoryBot: include build/create/etc. directly in specs.
  config.include FactoryBot::Syntax::Methods

  # ActiveJob test helpers (perform_enqueued_jobs, etc.).
  config.include ActiveJob::TestHelper

  # ActiveSupport time helpers (travel_to, freeze_time, etc.).
  config.include ActiveSupport::Testing::TimeHelpers

  # Run ActiveJob inline in test by default — the test adapter queues jobs.
  config.before(:each) do
    ActiveJob::Base.queue_adapter = :test
  end

  # System specs: default to rack_test, switch to headless Chrome for `js: true`.
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :headless_chrome
  end
end

# shoulda-matchers configuration.
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
