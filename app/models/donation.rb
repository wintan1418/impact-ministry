class Donation < ApplicationRecord
  FREQUENCIES   = %w[once monthly].freeze
  DESIGNATIONS  = %w[general youth education missions].freeze
  STATUSES      = %w[pending succeeded failed refunded canceled].freeze

  DESIGNATION_LABELS = {
    "general"   => "General Fund",
    "youth"     => "Youth",
    "education" => "Education",
    "missions"  => "Missions"
  }.freeze

  belongs_to :donor

  enum :frequency,   FREQUENCIES.zip(FREQUENCIES).to_h,    default: "once",    validate: true
  enum :designation, DESIGNATIONS.zip(DESIGNATIONS).to_h,  default: "general", validate: true
  enum :status,      STATUSES.zip(STATUSES).to_h,           default: "pending", validate: true

  validates :amount_cents, numericality: { greater_than_or_equal_to: 100, only_integer: true }
  validates :currency, presence: true
  validates :stripe_payment_intent_id, uniqueness: true, allow_nil: true
  validates :stripe_checkout_session_id, uniqueness: true, allow_nil: true

  scope :recent_first, -> { order(donated_at: :desc, created_at: :desc) }
  scope :succeeded_or_pending, -> { where(status: %w[succeeded pending]) }

  def amount_dollars
    amount_cents.to_i / 100.0
  end

  def amount_formatted
    whole = amount_dollars
    if whole == whole.to_i
      "$#{whole.to_i}"
    else
      format("$%.2f", whole)
    end
  end

  def designation_label
    DESIGNATION_LABELS.fetch(designation, designation.titleize)
  end

  def recurring?
    frequency == "monthly"
  end
end
