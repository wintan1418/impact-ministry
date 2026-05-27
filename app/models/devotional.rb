class Devotional < ApplicationRecord
  extend FriendlyId
  include PgSearch::Model

  friendly_id :title, use: :slugged

  has_rich_text :body
  has_one_attached :featured_image
  has_one_attached :audio

  belongs_to :author, class_name: "User"

  pg_search_scope :search_text,
    against: { title: "A", scripture_reference: "B", excerpt: "C" },
    using: {
      tsearch: { prefix: true },
      trigram: { threshold: 0.3 }
    }

  validates :title, presence: true
  validates :scripture_reference, presence: true
  validates :scheduled_for, presence: true, uniqueness: true
  validates :slug, uniqueness: true, allow_blank: true

  scope :published,     -> { where.not(published_at: nil) }
  scope :scheduled,     -> { where(published_at: nil) }
  scope :for_today,     -> { where(scheduled_for: Date.current) }
  scope :recent_first,  -> { order(scheduled_for: :desc) }
  scope :tagged,        ->(tag) { where("? = ANY(tags)", tag) }

  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.current) unless published?
  end

  def tomorrow
    self.class.find_by(scheduled_for: scheduled_for + 1.day)
  end

  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
end
