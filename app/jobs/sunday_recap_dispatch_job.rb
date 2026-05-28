# Runs every Sunday at 06:00 America/Chicago (see config/recurring.yml).
#
# Responsibilities:
#   1. Identify the 7-day window ending on `week_ending` (inclusive of Sunday).
#   2. Find all published devotionals scheduled in that window.
#   3. If fewer than 3 published devotionals exist for the week, log a
#      warning and skip the send — a thin week doesn't deserve a recap.
#   4. Otherwise enqueue one SundayRecapDeliveryJob per active subscriber.
#
# Idempotency:
#   - Re-running the job will re-enqueue all active subscribers. Unlike
#     DevotionalDispatchJob there is no per-subscriber recap row, so
#     callers should treat this as a manual replay tool only.
#
# See CLAUDE.md §5 (Sunday recap email — visually distinct).
class SundayRecapDispatchJob < ApplicationJob
  queue_as :devotionals

  MIN_DEVOTIONALS_FOR_RECAP = 3

  def perform(week_ending: default_week_ending)
    week_ending = week_ending.to_date if week_ending.respond_to?(:to_date)
    window_start = week_ending - 6.days

    devotionals = Devotional
      .published
      .where(scheduled_for: window_start..week_ending)
      .recent_first

    if devotionals.size < MIN_DEVOTIONALS_FOR_RECAP
      Rails.logger.warn(
        "[SundayRecapDispatchJob] Only #{devotionals.size} published devotional(s) " \
        "in the window #{window_start.iso8601}..#{week_ending.iso8601} — skipping recap " \
        "(threshold is #{MIN_DEVOTIONALS_FOR_RECAP})."
      )
      return
    end

    enqueued = 0
    EmailSubscriber.active.find_each(batch_size: 200) do |subscriber|
      SundayRecapDeliveryJob.perform_later(
        subscriber_id: subscriber.id,
        week_ending: week_ending.iso8601
      )
      enqueued += 1
    end

    Rails.logger.info(
      "[SundayRecapDispatchJob] enqueued #{enqueued} recipients for week ending #{week_ending}."
    )
  end

  private

  def default_week_ending
    Time.current.in_time_zone(ENV.fetch("DEVOTIONAL_TIMEZONE", "America/Chicago")).to_date
  end
end
