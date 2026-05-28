class PodcastEpisodesController < ApplicationController
  # The RSS feed is consumed by Apple Podcasts, Overcast, RSS readers, etc.
  # Those clients don't send a modern-browser User-Agent, so skip the global
  # `allow_browser versions: :modern` filter for the feed action only.
  skip_before_action :allow_browser, only: :feed, raise: false

  def index
    @live              = ActiveModel::Type::Boolean.new.cast(ENV.fetch("PODCAST_LIVE_ENABLED", false))
    @latest_episode    = PodcastEpisode.published.recent_first.first
    @past_episodes     = PodcastEpisode.published.recent_first.where.not(id: @latest_episode&.id).limit(20)
  end

  def show
    @episode = PodcastEpisode.friendly.find(params[:slug])
    raise ActiveRecord::RecordNotFound unless @episode.published?
  end

  # Apple-Podcasts-compliant RSS feed (XML 1.0 + RSS 2.0 + itunes namespace).
  # Cached for 30 minutes, keyed by the most recent episode `updated_at` so
  # the cache busts the moment an editor publishes/edits in /admin.
  # See docs/ROUTES.md and CLAUDE.md §5 (Podcast surface).
  def feed
    @episodes = PodcastEpisode.published.recent_first.limit(200)
    @host     = ENV.fetch("APP_HOST", request.host_with_port)
    @protocol = ENV.fetch("APP_PROTOCOL", request.protocol.delete(":/"))

    cache_key = "podcast.rss-#{PodcastEpisode.published.maximum(:updated_at)&.to_i}"
    cached = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      render_to_string :feed, layout: false, formats: [ :rss ]
    end

    response.headers["Content-Type"] = "application/rss+xml; charset=utf-8"
    render plain: cached, content_type: "application/rss+xml"
  end
end
