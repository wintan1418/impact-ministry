# Notifies editors that a new partnership intake has landed. Sent on the
# :mailers queue so the public form returns instantly. Idempotent —
# re-runs send the alert again (Postmark de-duplicates on its side; if we
# need stricter "exactly once" semantics, add a `notified_at` column and
# short-circuit here).
#
# See PartnershipsController#create.
class PartnershipNotificationJob < ApplicationJob
  queue_as :mailers

  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 5
  retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

  # Postmark::ApiInputError is only defined when the postmark gem is loaded.
  # Guard the retry_on so the file loads cleanly in environments without it.
  if defined?(Postmark::ApiInputError)
    retry_on Postmark::ApiInputError, wait: :polynomially_longer, attempts: 3
  end

  discard_on ActiveRecord::RecordNotFound

  def perform(partnership_id)
    partnership = Partnership.find(partnership_id)
    AdminAlertMailer.with(partnership_id: partnership.id).new_partnership.deliver_now
  end
end
