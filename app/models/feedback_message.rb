# FeedbackMessage — public contact form submission.
#
# One row per /contact form submit. Captures the writer's name + email, an
# optional subject line, the note body, and a `kind` (general | prayer |
# partnership | press | bug) so editors can triage in the admin queue.
#
# Lifecycle (see docs/DOMAIN.md): submitted → replied (via `mark_replied!`).
# Hard-delete on archive/spam.
#
# Submissions never link to a User. Editors are notified by
# `FeedbackNotificationJob` so they can answer from their own inbox.
class FeedbackMessage < ApplicationRecord
  KINDS = %w[general prayer partnership press bug].freeze

  enum :kind, KINDS.zip(KINDS).to_h, default: "general", validate: true

  normalizes :email, with: ->(e) { e.to_s.strip.downcase }

  validates :name,  presence: true, length: { minimum: 1, maximum: 120 }
  validates :email, presence: true,
                    length: { minimum: 5, maximum: 160 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :body,  presence: true, length: { minimum: 6, maximum: 6000 }

  scope :unread,       -> { where(replied: false) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :by_kind,      ->(kind) { where(kind: kind) }

  # Mark this message as replied-to. Editors call this from the admin
  # show page once they've answered from their own inbox.
  def mark_replied!(at: Time.current)
    update!(replied: true, replied_at: at)
  end

  def to_s
    subject.presence || body.to_s.truncate(60)
  end
end
