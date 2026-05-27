# Email subscriber — captured from one of several public surfaces (footer,
# inline mid-content, exit intent, prayer-form upsell, podcast page,
# resource download, manual). One row per email; re-subscribes are
# idempotent and wipe `unsubscribed_at`.
#
# See CLAUDE.md §4 (shape) and docs/DOMAIN.md (lifecycle).
class EmailSubscriber < ApplicationRecord
  SOURCES = %w[footer inline exit_intent prayer podcast resource_download manual].freeze

  enum :source, SOURCES.zip(SOURCES).to_h, default: "manual", validate: true

  normalizes :email, with: ->(e) { e.to_s.strip.downcase }

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :token, presence: true, uniqueness: true

  before_validation :ensure_token
  before_create :stamp_subscribed_at

  scope :active,       -> { where(unsubscribed_at: nil) }
  scope :unsubscribed, -> { where.not(unsubscribed_at: nil) }

  def active?
    unsubscribed_at.nil?
  end

  # Idempotent — calling on an already-active subscriber leaves the row in a
  # valid active state with a fresh `subscribed_at`.
  def resubscribe!
    update!(unsubscribed_at: nil, subscribed_at: Time.current)
  end

  def unsubscribe!
    update!(unsubscribed_at: Time.current)
  end

  def to_s
    name.presence || email
  end

  private

  def ensure_token
    self.token ||= SecureRandom.urlsafe_base64(24)
  end

  def stamp_subscribed_at
    self.subscribed_at ||= Time.current
  end
end
