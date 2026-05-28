class DevotionalHighlight < ApplicationRecord
  belongs_to :user
  belongs_to :devotional

  validates :text_range, presence: true, length: { maximum: 6000 }

  scope :recent_first, -> { order(saved_at: :desc) }

  before_validation :stamp_saved_at

  # text_range is JSON-stringified: {"start": 120, "end": 280, "text": "..."}
  def parsed_range
    @parsed_range ||= JSON.parse(text_range.to_s)
  rescue JSON::ParserError
    {}
  end

  def excerpt
    parsed_range.fetch("text", "").to_s.truncate(280)
  end

  private

  def stamp_saved_at
    self.saved_at ||= Time.current
  end
end
