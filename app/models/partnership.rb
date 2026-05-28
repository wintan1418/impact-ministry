# Partnership — public intake submission from a church, nonprofit, school,
# business, or other partner-shaped organization.
#
# One row per /partner form submit. Captures the organization's name + type,
# a contact person (name, email, optional phone), the interest areas they
# want to explore with us, and a free-form note. Editors triage the queue
# through the admin inbox (status: new → in_review → engaged / declined /
# archived). See docs/DOMAIN.md.
#
# Submissions never link to a User. Editors are notified by
# `PartnershipNotificationJob` so they can answer from their own inbox.
class Partnership < ApplicationRecord
  ORGANIZATION_TYPES = %w[church nonprofit school business other].freeze
  INTEREST_AREAS     = %w[devotionals podcast grants content volunteers other].freeze
  STATUSES           = %w[new in_review engaged declined archived].freeze

  enum :organization_type,
       ORGANIZATION_TYPES.zip(ORGANIZATION_TYPES).to_h,
       default: "other",
       validate: true

  enum :status,
       STATUSES.zip(STATUSES).to_h,
       default: "new",
       validate: true,
       prefix: :status

  normalizes :contact_email, with: ->(e) { e.to_s.strip.downcase }
  normalizes :interest_areas, with: ->(values) { Array(values).map(&:to_s).reject(&:blank?).uniq }

  validates :organization_name, presence: true, length: { minimum: 1, maximum: 160 }
  validates :contact_name,      presence: true, length: { minimum: 1, maximum: 120 }
  validates :contact_email,     presence: true,
                                length: { minimum: 5, maximum: 160 },
                                format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :contact_phone, length: { maximum: 40 }, allow_blank: true
  validates :message,       presence: true, length: { minimum: 10, maximum: 6000 }

  validate :interest_areas_must_be_subset

  scope :unread,       -> { where(status: "new") }
  scope :recent_first, -> { order(created_at: :desc) }

  ORGANIZATION_LABELS = {
    "church"    => "Church",
    "nonprofit" => "Nonprofit",
    "school"    => "School",
    "business"  => "Business",
    "other"     => "Other"
  }.freeze

  INTEREST_LABELS = {
    "devotionals" => "Devotionals",
    "podcast"     => "Podcast",
    "grants"      => "Grants",
    "content"     => "Content",
    "volunteers"  => "Volunteers",
    "other"       => "Other"
  }.freeze

  def kind_label
    ORGANIZATION_LABELS[organization_type] || organization_type.to_s.titleize
  end

  def interests_label
    Array(interest_areas)
      .map { |a| INTEREST_LABELS[a] || a.to_s.titleize }
      .join(" · ")
  end

  def to_s
    organization_name.to_s
  end

  private

  def interest_areas_must_be_subset
    return if interest_areas.blank?

    bad = Array(interest_areas).reject { |a| INTEREST_AREAS.include?(a) }
    return if bad.empty?

    errors.add(:interest_areas, "contains unknown values: #{bad.join(', ')}")
  end
end
