class PodcastEpisode < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  include PgSearch::Model
  pg_search_scope :search_text,
    against: { title: "A", description: "B", transcript: "C" },
    using: { tsearch: { prefix: true }, trigram: { threshold: 0.3 } }

  validates :title, :scheduled_for, :episode_number, presence: true
  validates :slug, uniqueness: true
  validates :episode_number, uniqueness: { scope: :season }

  scope :published,    -> { where.not(published_at: nil) }
  scope :scheduled,    -> { where(published_at: nil) }
  # Order by air date (the user-facing concept of "newest"), not internal
  # publish timestamp — those can be tied when bulk-publishing seeds.
  scope :recent_first, -> { order(scheduled_for: :desc) }

  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.current) unless published?
  end

  def duration_label
    return nil unless duration_seconds
    mins = duration_seconds / 60
    "#{mins} min"
  end

  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
end
