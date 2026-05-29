class Donor < ApplicationRecord
  belongs_to :user, optional: true
  has_many :donations, dependent: :restrict_with_exception

  normalizes :email, with: ->(e) { e.to_s.strip.downcase }
  validates :email, presence: true
  validates :stripe_customer_id, uniqueness: true, allow_nil: true

  scope :recent_first, -> { order(created_at: :desc) }

  def display_name
    name.presence || email
  end
end
