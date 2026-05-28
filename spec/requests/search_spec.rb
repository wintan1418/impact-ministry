require "rails_helper"

RSpec.describe "Search", type: :request do
  describe "GET /search/overlay" do
    it "renders the overlay shell with the input + results frame" do
      get "/search/overlay"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="q"')
      expect(response.body).to include('id="search-results"')
    end
  end

  describe "GET /search with an empty query" do
    it "returns a 200 + curated suggestions (today's devotional + recent content)" do
      create(:devotional, :published, :for_today, title: "Quieted By His Love")
      create(:podcast_episode, :published, title: "On Waiting Well")
      create(:resource, :published, title: "Thirty Days of Habakkuk")

      get "/search"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Quieted By His Love")
      expect(response.body).to include("Recent")
    end
  end

  describe "GET /search?q=<term>" do
    it "matches devotionals by title via pg_search" do
      hit  = create(:devotional, :published, title: "When the Vision Tarries")
      miss = create(:devotional, :published, title: "A Lamp at Midnight")

      get "/search", params: { q: "vision" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(hit.title)
      expect(response.body).not_to include(miss.title)
    end

    it "matches podcast episodes by title" do
      hit = create(:podcast_episode, :published, title: "Mornings with Mara")

      get "/search", params: { q: "Mornings" }

      expect(response.body).to include(hit.title)
    end

    it "matches resources by title" do
      hit = create(:resource, :published, title: "Sermons on Waiting", category: "sermon")

      get "/search", params: { q: "Sermons" }

      expect(response.body).to include(hit.title)
    end

    it "matches approved testimonies by body via ILIKE" do
      approved = create(:testimony, :approved, body: "He answered my prayer for a quieter morning routine.")
      _hidden  = create(:testimony,              body: "He answered my prayer for a quieter evening routine.")

      get "/search", params: { q: "quieter morning" }

      expect(response.body).to include("quieter morning")
      expect(response.body).not_to include("quieter evening")
      expect(approved).to be_present
    end

    it "renders a quiet empty state when nothing matches" do
      get "/search", params: { q: "xyznonexistentqueryterm" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Try a shorter search")
    end
  end
end
