# PrayerRequest — public form submission for the prayer wall.
#
# Lifecycle (see docs/DOMAIN.md):
#   new → praying → answered → archived
#
# `is_public` is an independently toggleable flag — admins may approve a
# request to be prayed for internally without surfacing it on /pray.
#
# `prayed_count` is incremented atomically on each "I prayed for this" tap.
# Per-session dedupe is handled in the controller (session[:prayed_for]).
class PrayerRequest < ApplicationRecord
  STATUSES = %w[new praying answered archived].freeze

  # `prefix: true` keeps the `:new` status from clashing with `PrayerRequest.new`.
  # Use `status_new?` / `status_praying?` etc. on instances.
  enum :status, STATUSES.zip(STATUSES).to_h, default: "new", validate: true, prefix: true

  normalizes :email, with: ->(e) { e.to_s.strip.downcase.presence }

  validates :body, presence: true, length: { minimum: 6, maximum: 2000 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :visible, -> {
    where(status: %w[praying answered], is_public: true).order(created_at: :desc)
  }
  scope :answered_only,      -> { where(status: "answered", is_public: true) }
  scope :pending_moderation, -> { where(status: "new") }

  # Returns "Anonymous" if `is_anonymous` is set or `name` is blank. Otherwise
  # returns the provided name. Used by the public wall and admin index.
  def display_name
    return "Anonymous" if is_anonymous? || name.blank?

    name
  end

  # Atomic +1 to prayed_count. Returns the reloaded record.
  def increment_prayed!
    self.class.increment_counter(:prayed_count, id)
    reload
  end

  def to_s
    body.to_s.truncate(80)
  end
end
