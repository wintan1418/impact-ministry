# Notifies editors that a new prayer request has landed. Sent on the
# :mailers queue so the public form returns instantly. Skipped (with
# a log line) if ADMIN_NOTIFICATION_EMAIL is unset — useful in CI.
# Mirrors PartnershipNotificationJob.
class PrayerNotificationJob < ApplicationJob
  queue_as :mailers

  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 5
  retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

  if defined?(Postmark::ApiInputError)
    retry_on Postmark::ApiInputError, wait: :polynomially_longer, attempts: 3
  end

  discard_on ActiveRecord::RecordNotFound

  def perform(prayer_request_id)
    return if ENV["ADMIN_NOTIFICATION_EMAIL"].blank?

    prayer = PrayerRequest.find(prayer_request_id)
    AdminAlertMailer.with(prayer_request_id: prayer.id).new_prayer.deliver_now
  end
end
