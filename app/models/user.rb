class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :devotional_highlights, dependent: :destroy
  has_many :highlighted_devotionals, through: :devotional_highlights, source: :devotional

  ROLES = %w[visitor subscriber editor admin].freeze
  enum :role, ROLES.zip(ROLES).to_h, default: "subscriber", validate: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :staff,     -> { where(role: %w[editor admin]) }

  def confirmed?
    confirmed_at.present?
  end

  def staff?
    editor? || admin?
  end

  # ActiveAdmin display helper.
  def to_s
    name.presence || email_address
  end
end
