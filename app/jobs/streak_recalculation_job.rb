# Runs daily at 02:00 America/Chicago (see config/recurring.yml).
#
# Responsibilities:
#   For every subscriber/editor/admin user, decide whether they "read"
#   on the supplied date and roll their streak fields forward.
#
# A user is considered to have "read" on `date` if EITHER:
#   (a) any DevotionalDelivery whose email_subscriber.email matches the
#       user's email_address (case-insensitive) has `opened_at` falling
#       inside `date.all_day`; OR
#   (b) the user has any DevotionalHighlight with `saved_at` inside
#       `date.all_day`.
#
# Streak transitions applied per user (see CLAUDE.md §5):
#   1. First read ever (last_read_on nil, read today)
#        -> current_streak = 1, longest = max(longest, 1), last_read_on = date.
#   2. Consecutive day (last_read_on == date - 1, read today)
#        -> current_streak += 1, longest = max(longest, current), last_read_on = date.
#   3. Same-day re-read (last_read_on == date, read today)
#        -> no change (idempotent).
#   4. Streak broken with a read today (last_read_on < date - 1, read today)
#        -> current_streak = 1, longest unchanged unless it grew,
#           last_read_on = date.
#   5. No read today, last_read >= 2 days ago
#        -> current_streak = 0, last_read_on unchanged.
#
# Idempotent: re-running for the same date produces the same end state.
#
# See CLAUDE.md §5 (Habit mechanics).
class StreakRecalculationJob < ApplicationJob
  queue_as :default

  STREAK_ROLES = %w[subscriber editor admin].freeze

  def perform(date: default_date)
    date = date.to_date
    window = date.all_day

    processed = 0
    ticked    = 0
    broken    = 0

    User.where(role: STREAK_ROLES).find_each(batch_size: 200) do |user|
      processed += 1
      read = read_on?(user, date, window)

      outcome = User.transaction { apply_transition(user, date, read: read) }

      case outcome
      when :ticked  then ticked  += 1
      when :broken  then broken  += 1
      end
    end

    Rails.logger.info(
      "[StreakRecalculationJob] processed #{processed} users; " \
      "#{ticked} streaks ticked; #{broken} broken."
    )
  end

  private

  def default_date
    Time.current.in_time_zone(
      ENV.fetch("DEVOTIONAL_TIMEZONE", "America/Chicago")
    ).to_date
  end

  # Signal (a): a DevotionalDelivery for one of the user's matching
  # EmailSubscriber rows opened inside the date window. Signal (b): the
  # user saved a highlight inside the date window. Either is enough.
  def read_on?(user, _date, window)
    return true if user.devotional_highlights.where(saved_at: window).exists?

    subscriber_ids = EmailSubscriber
      .where("LOWER(email) = ?", user.email_address.to_s.downcase)
      .pluck(:id)
    return false if subscriber_ids.empty?

    DevotionalDelivery
      .where(email_subscriber_id: subscriber_ids, opened_at: window)
      .exists?
  end

  # Returns :ticked when current_streak grew (cases 1, 2, 4),
  # :broken when current_streak reset to 0 (case 5),
  # or nil for no-op (case 3, or no-read with already-zero streak).
  def apply_transition(user, date, read:)
    last = user.last_read_on

    if read
      if last.nil? || last < date - 1
        # Case 1 (no prior read) or case 4 (streak broken, fresh start today).
        new_current = 1
        new_longest = [ user.longest_streak, new_current ].max
        user.update!(
          current_streak: new_current,
          longest_streak: new_longest,
          last_read_on:   date
        )
        :ticked
      elsif last == date - 1
        # Case 2 — consecutive day.
        new_current = user.current_streak + 1
        new_longest = [ user.longest_streak, new_current ].max
        user.update!(
          current_streak: new_current,
          longest_streak: new_longest,
          last_read_on:   date
        )
        :ticked
      else
        # Case 3 — already counted today. No change.
        nil
      end
    else
      # No read today.
      if last && last < date - 1 && user.current_streak.positive?
        # Case 5 — streak lapsed.
        user.update!(current_streak: 0)
        :broken
      else
        nil
      end
    end
  end
end
