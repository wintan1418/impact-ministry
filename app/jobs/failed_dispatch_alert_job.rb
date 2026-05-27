# Failsafe — runs daily at 06:00 America/Chicago, one hour after the
# DevotionalDispatchJob attempt. If no devotional has been published
# for today, emails ENV["ADMIN_NOTIFICATION_EMAIL"] so editors can
# react before the morning rush.
#
# See CLAUDE.md §5 (Daily devotional dispatch — failsafe).
class FailedDispatchAlertJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 3
  retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 3

  if defined?(Postmark::ApiInputError)
    retry_on Postmark::ApiInputError, wait: :polynomially_longer, attempts: 3
  end

  def perform
    if Devotional.published.for_today.exists?
      Rails.logger.info(
        "[FailedDispatchAlertJob] Devotional already published for #{Date.current.iso8601} — no alert needed."
      )
      return
    end

    Rails.logger.warn(
      "[FailedDispatchAlertJob] No published devotional for #{Date.current.iso8601} — alerting #{recipient}."
    )

    AdminAlertMailer.with(date: Date.current).missing_devotional.deliver_now
  end

  private

  def recipient
    ENV.fetch("ADMIN_NOTIFICATION_EMAIL", "team@impactministry.org")
  end
end
