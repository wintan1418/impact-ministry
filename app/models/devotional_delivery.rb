# Records a single (devotional, subscriber) email send. Created by
# DevotionalDeliveryJob, updated by the Postmark webhook pipeline as
# opens and clicks come in.
#
# Idempotency:
#   The (devotional_id, email_subscriber_id) tuple is uniquely indexed,
#   so re-running the dispatcher cannot double-send.
#
# Correlation with Postmark:
#   We store the Postmark MessageID on `postmark_message_id` after a
#   successful send. The webhook receiver looks rows up by that ID.
#
# See CLAUDE.md §4 (Audience) + §5 (daily devotional dispatch flow).
class DevotionalDelivery < ApplicationRecord
  belongs_to :devotional
  belongs_to :email_subscriber

  validates :sent_at, presence: true
  validates :email_subscriber_id, uniqueness: { scope: :devotional_id }

  scope :opened,  -> { where.not(opened_at: nil) }
  scope :clicked, -> { where.not(clicked_at: nil) }

  # Mark this delivery as opened. First open wins — Postmark may fire
  # multiple Open events for the same message (multiple inbox loads).
  def open!(at: Time.current)
    return if opened_at

    update!(opened_at: at)
  end

  # Mark this delivery as clicked. Clicks imply an open even if the Open
  # event hasn't arrived yet — backfill opened_at if it's still nil.
  def click!(at: Time.current)
    update!(clicked_at: at, opened_at: opened_at || at)
  end
end
