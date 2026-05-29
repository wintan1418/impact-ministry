# Volunteer — public intake from someone who'd like to give time to the
# ministry (writing, podcast production, prayer wall coverage, events,
# design, social media, etc.). Mirrors Partnership in shape so editors get
# a single mental model: queue, triage status, admin inbox.
#
# Submissions never link to a User. Editors are notified by
# VolunteerNotificationJob.
class Volunteer < ApplicationRecord
  INTEREST_AREAS = %w[
    writing
    podcast_production
    design
    social_media
    events
    prayer
    teaching
    outreach
    other
  ].freeze

  AVAILABILITIES = %w[
    weekdays
    weeknights
    weekends
    flexible
    one_time_events
  ].freeze

  STATUSES = %w[new in_review engaged declined archived].freeze

  enum :availability,
       AVAILABILITIES.zip(AVAILABILITIES).to_h,
       default: "flexible",
       validate: true

  enum :status,
       STATUSES.zip(STATUSES).to_h,
       default: "new",
       validate: true,
       prefix: :status

  normalizes :email,          with: ->(e) { e.to_s.strip.downcase }
  normalizes :interest_areas, with: ->(values) { Array(values).map(&:to_s).reject(&:blank?).uniq }

  validates :name,    presence: true, length: { minimum: 1, maximum: 120 }
  validates :email,   presence: true,
                      length: { minimum: 5, maximum: 160 },
                      format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone,   length: { maximum: 40 }, allow_blank: true
  validates :gifts,   length: { maximum: 4000 }, allow_blank: true
  validates :message, presence: true, length: { minimum: 10, maximum: 6000 }

  validate :interest_areas_must_be_subset

  scope :unread,       -> { where(status: "new") }
  scope :recent_first, -> { order(created_at: :desc) }

  INTEREST_LABELS = {
    "writing"            => "Writing",
    "podcast_production" => "Podcast production",
    "design"             => "Design",
    "social_media"       => "Social media",
    "events"             => "Events",
    "prayer"             => "Prayer wall",
    "teaching"           => "Teaching",
    "outreach"           => "Outreach",
    "other"              => "Other"
  }.freeze

  AVAILABILITY_LABELS = {
    "weekdays"        => "Weekdays",
    "weeknights"      => "Weeknights",
    "weekends"        => "Weekends",
    "flexible"        => "Flexible",
    "one_time_events" => "One-time events"
  }.freeze

  def interests_label
    Array(interest_areas)
      .map { |a| INTEREST_LABELS[a] || a.to_s.titleize }
      .join(" · ")
  end

  def availability_label
    AVAILABILITY_LABELS[availability] || availability.to_s.titleize
  end

  def to_s
    name.to_s.presence || email
  end

  private

  def interest_areas_must_be_subset
    return if interest_areas.blank?

    bad = Array(interest_areas).reject { |a| INTEREST_AREAS.include?(a) }
    return if bad.empty?

    errors.add(:interest_areas, "contains unknown values: #{bad.join(', ')}")
  end
end
