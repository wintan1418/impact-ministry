require "rails_helper"

RSpec.describe "Podcast RSS feed", type: :request do
  describe "GET /podcast.rss" do
    it "returns HTTP 200" do
      get "/podcast.rss"
      expect(response).to have_http_status(:ok)
    end

    it "sets an application/rss+xml content type" do
      get "/podcast.rss"
      expect(response.media_type).to eq("application/rss+xml")
    end

    it "renders a well-formed RSS 2.0 envelope with the itunes namespace" do
      get "/podcast.rss"
      expect(response.body).to include('<rss version="2.0"')
      expect(response.body).to include('xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"')
      expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
    end

    it "sets the channel-level title to IMPACT Ministry" do
      get "/podcast.rss"
      expect(response.body).to include("<title>IMPACT Ministry</title>")
    end

    it "includes a published episode's title, guid, link, and RFC822 pubDate" do
      Rails.cache.clear
      episode = create(:podcast_episode, :published,
        title: "Waiting Well in the Delta",
        season: 1,
        episode_number: 7,
        published_at: Time.utc(2026, 1, 15, 12, 0, 0))

      get "/podcast.rss"

      expect(response.body).to include("Waiting Well in the Delta")
      expect(response.body).to include("/podcast/#{episode.slug}")
      # RFC822 example: "Thu, 15 Jan 2026 12:00:00 +0000"
      expect(response.body).to match(/[A-Z][a-z]{2}, \d{2} [A-Z][a-z]{2} \d{4} \d{2}:\d{2}:\d{2} [+-]\d{4}/)
    end

    it "excludes unpublished (scheduled) episodes" do
      Rails.cache.clear
      hidden = create(:podcast_episode, :scheduled, title: "Not Yet Aired")

      get "/podcast.rss"

      expect(response.body).not_to include(hidden.title)
    end

    it "renders itunes:duration in HH:MM:SS for an episode with duration_seconds set" do
      Rails.cache.clear
      create(:podcast_episode, :published,
        title: "Half-Hour Talk",
        duration_seconds: 1_845) # 00:30:45

      get "/podcast.rss"

      expect(response.body).to include("<itunes:duration>00:30:45</itunes:duration>")
    end

    it "embeds itunes:season and itunes:episode tags per item" do
      Rails.cache.clear
      create(:podcast_episode, :published, season: 2, episode_number: 3)

      get "/podcast.rss"

      expect(response.body).to include("<itunes:season>2</itunes:season>")
      expect(response.body).to include("<itunes:episode>3</itunes:episode>")
    end

    it "appends guest names to content:encoded when present" do
      Rails.cache.clear
      create(:podcast_episode, :published, :with_guests,
        title: "Conversation with Friends",
        description: "A warm talk.")

      get "/podcast.rss"

      expect(response.body).to include("Mara Jenkins")
      expect(response.body).to include("Theo Banks")
    end
  end
end
