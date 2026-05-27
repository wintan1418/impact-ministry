# Sends the one-time welcome email to a newly captured (or re-subscribed)
# EmailSubscriber. Idempotent — re-runs deliver again, which Postmark
# de-duplicates inside its own pipeline. If we ever need stricter "exactly
# once" semantics, add a `welcomed_at` column and short-circuit here.
class WelcomeEmailJob < ApplicationJob
  queue_as :mailers

  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 5
  retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

  # Postmark::ApiInputError is only defined when the postmark gem is loaded.
  # Guard the retry_on so the file loads cleanly in environments without it.
  if defined?(Postmark::ApiInputError)
    retry_on Postmark::ApiInputError, wait: :polynomially_longer, attempts: 3
  end

  discard_on ActiveRecord::RecordNotFound

  def perform(subscriber_id)
    subscriber = EmailSubscriber.find(subscriber_id)
    return unless subscriber.active?

    SubscriberMailer.with(subscriber: subscriber).welcome.deliver_now
  end
end
