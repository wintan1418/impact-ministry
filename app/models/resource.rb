# Resource — a downloadable artifact in the Resource Library: guides,
# devotional collections, sermons, studies, curriculum, and other media. Public
# read access via /resources. Some downloads are email-gated (creating an
# EmailSubscriber with source="resource_download" on first capture).
#
# See CLAUDE.md §4 (shape), docs/DOMAIN.md, and Richard's content plan §3.
class Resource < ApplicationRecord
  extend FriendlyId
  include PgSearch::Model

  friendly_id :title, use: :slugged

  has_one_attached :file

  CATEGORIES = %w[guide devotional_collection sermon study curriculum media].freeze

  enum :category, CATEGORIES.zip(CATEGORIES).to_h, default: "guide", validate: true

  pg_search_scope :search_text,
    against: { title: "A", description: "B" },
    using: {
      tsearch: { prefix: true },
      trigram: { threshold: 0.3 }
    }

  validates :title, presence: true
  validates :slug, uniqueness: true, allow_blank: true

  scope :published,    -> { where.not(published_at: nil) }
  scope :featured,     -> { where(featured: true) }
  scope :recent_first, -> { order(published_at: :desc) }
  scope :by_category,  ->(cat) { where(category: cat) }

  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.current) unless published?
  end

  # Atomic counter increment — avoids the lost-update race that
  # `update!(downloads_count: downloads_count + 1)` would introduce when
  # two visitors download at once.
  def increment_downloads!
    self.class.increment_counter(:downloads_count, id)
    reload
  end

  def category_label
    category.to_s.tr("_", " ").titleize
  end

  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
end
