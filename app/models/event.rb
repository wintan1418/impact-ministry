# Event — a community gathering (workshop, podcast taping, launch celebration,
# devotional brunch, etc.). RSVPs are anonymous-first: anyone with the link can
# save a seat without an account. Capacity is optional; nil capacity means an
# open invitation.
#
# See CLAUDE.md §4, docs/DOMAIN.md, and Richard's content plan §7.
class Event < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  has_many :event_rsvps, dependent: :destroy

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :virtual_link,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) },
            allow_blank: true

  scope :published,            -> { where(published: true) }
  scope :upcoming,             -> { where("starts_at >= ?", Time.current) }
  scope :past,                 -> { where("starts_at < ?", Time.current) }
  scope :chronological,        -> { order(:starts_at) }
  scope :reverse_chronological, -> { order(starts_at: :desc) }

  # An event is "over" once its ends_at has passed. When ends_at is blank, we
  # consider an event over 24 hours after it started (so a same-day gathering
  # falls out of the RSVP window naturally).
  def over?
    if ends_at?
      ends_at < Time.current
    else
      starts_at < 24.hours.ago
    end
  end

  def rsvp_seat_count
    event_rsvps.sum(:party_size)
  end

  def seats_remaining
    return nil unless capacity
    [ capacity - rsvp_seat_count, 0 ].max
  end

  def full?
    capacity.present? && rsvp_seat_count >= capacity
  end

  def virtual?
    virtual_link.present? && location.blank?
  end

  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
end
