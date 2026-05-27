# Runs daily at 05:00 America/Chicago (see config/recurring.yml).
#
# Responsibilities:
#   1. Find today's scheduled, unpublished devotional.
#   2. Publish it (`Devotional#publish!`).
#   3. Enqueue one DevotionalDeliveryJob per active EmailSubscriber.
#
# Idempotency:
#   - `Devotional#publish!` short-circuits if already published.
#   - DevotionalDelivery has a unique (devotional, subscriber) index, so
#     re-running the dispatcher cannot double-send. We also pre-filter
#     subscribers that already have a delivery row.
#
# Failure mode:
#   - If no devotional is scheduled for today, this job logs a warning
#     and returns; FailedDispatchAlertJob picks up the alert at 06:00.
#
# See CLAUDE.md §5 (Daily devotional dispatch).
class DevotionalDispatchJob < ApplicationJob
  queue_as :devotionals

  def perform
    devotional = Devotional.for_today.first

    if devotional.nil?
      Rails.logger.warn(
        "[DevotionalDispatchJob] No devotional scheduled for #{Date.current.iso8601} — skipping. " \
        "FailedDispatchAlertJob will alert editors at 06:00."
      )
      return
    end

    devotional.publish! unless devotional.published?

    # Subscribers that already have a delivery row for this devotional are
    # skipped — re-running the dispatcher never double-enqueues.
    already_sent_ids = DevotionalDelivery
      .where(devotional_id: devotional.id)
      .pluck(:email_subscriber_id)

    scope = EmailSubscriber.active
    scope = scope.where.not(id: already_sent_ids) if already_sent_ids.any?

    enqueued = 0
    scope.find_each(batch_size: 200) do |subscriber|
      DevotionalDeliveryJob.perform_later(
        devotional_id: devotional.id,
        subscriber_id: subscriber.id
      )
      enqueued += 1
    end

    Rails.logger.info(
      "[DevotionalDispatchJob] Devotional ##{devotional.id} (#{devotional.title}) " \
      "dispatched to #{enqueued} subscriber(s)."
    )
  end
end
