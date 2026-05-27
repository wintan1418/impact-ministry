class PodcastEpisodesController < ApplicationController
  def index
    @live              = ActiveModel::Type::Boolean.new.cast(ENV.fetch("PODCAST_LIVE_ENABLED", false))
    @latest_episode    = PodcastEpisode.published.recent_first.first
    @past_episodes     = PodcastEpisode.published.recent_first.where.not(id: @latest_episode&.id).limit(20)
  end

  def show
    @episode = PodcastEpisode.friendly.find(params[:slug])
    raise ActiveRecord::RecordNotFound unless @episode.published?
  end
end
