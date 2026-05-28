# Testimony — a public-facing "what God did" submission.
#
# Lifecycle (see docs/DOMAIN.md):
#   submitted (approved: false) → approved (approved: true) → optionally featured.
# Approval is editor-only; the public form always creates rows with
# approved: false. Featured testimonies rotate into the homepage navy band.
#
# Photo is optional and attached via ActiveStorage. We resize on display.
class Testimony < ApplicationRecord
  has_one_attached :photo

  validates :body, presence: true,
                   length: { minimum: 20, maximum: 4000 }
  validates :name,     length: { maximum: 80 },  allow_blank: true
  validates :location, length: { maximum: 100 }, allow_blank: true

  before_validation :stamp_submitted_at
  after_update :stamp_approved_at, if: :saved_change_to_approved?

  scope :approved,        -> { where(approved: true) }
  scope :featured,        -> { where(featured: true) }
  scope :submitted_first, -> { order(submitted_at: :desc) }
  scope :recent_first,    -> { order(submitted_at: :desc) }

  # Display fallback so the wall never shows a blank byline.
  def display_name
    name.presence || "A friend"
  end

  # A short, quote-friendly extract — first sentence, or first ~140 chars.
  # Used in cards and homepage rotation.
  def pull_quote
    return "" if body.blank?

    trimmed = body.strip
    first_sentence = trimmed.split(/(?<=[.!?])\s+/).first.to_s
    candidate = first_sentence.presence || trimmed
    candidate.length > 140 ? "#{candidate[0, 137].rstrip}…" : candidate
  end

  def to_s
    pull_quote
  end

  private

  def stamp_submitted_at
    self.submitted_at ||= Time.current
  end

  def stamp_approved_at
    if approved?
      update_column(:approved_at, Time.current) if approved_at.nil?
    else
      update_column(:approved_at, nil) if approved_at.present?
    end
  end
end
