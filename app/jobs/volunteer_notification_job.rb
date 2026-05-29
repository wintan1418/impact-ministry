# Notifies editors that a new volunteer signup landed. Mirrors
# PartnershipNotificationJob.
class VolunteerNotificationJob < ApplicationJob
  queue_as :mailers

  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 5
  retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

  if defined?(Postmark::ApiInputError)
    retry_on Postmark::ApiInputError, wait: :polynomially_longer, attempts: 3
  end

  discard_on ActiveRecord::RecordNotFound

  def perform(volunteer_id)
    return if ENV["ADMIN_NOTIFICATION_EMAIL"].blank?

    volunteer = Volunteer.find(volunteer_id)
    AdminAlertMailer.with(volunteer_id: volunteer.id).new_volunteer.deliver_now
  end
end
