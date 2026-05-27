# Static, editor-managed pages (about, beliefs, contact, privacy, terms, plus
# anything the team adds via ActiveAdmin). Resolved by slug via PagesController.
#
# See docs/DOMAIN.md and CLAUDE.md §4.
class Page < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  has_rich_text :body

  validates :title, presence: true
  validates :slug,  presence: true, uniqueness: { case_sensitive: false }

  scope :published, -> { where(published: true) }

  def to_param
    slug
  end

  # Regenerate the slug from the title when the title changes or no slug is
  # set. Respect any explicit slug write (seeds + admin) — if the slug column
  # was just assigned, don't overwrite it on save.
  def should_generate_new_friendly_id?
    return false if slug_changed? && slug.present?

    title_changed? || slug.blank?
  end
end
