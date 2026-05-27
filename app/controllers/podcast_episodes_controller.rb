class PodcastEpisodesController < ApplicationController
  # Phase 2.1–2.5 will replace this placeholder with the real episode model.
  def index
    @live = ActiveModel::Type::Boolean.new.cast(ENV.fetch("PODCAST_LIVE_ENABLED", false))
  end
end
