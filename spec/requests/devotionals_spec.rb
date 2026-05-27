require "rails_helper"

RSpec.describe "Devotionals", type: :request do
  describe "GET /devotionals/today" do
    it "renders the no_today fallback when no published devotional is scheduled for today" do
      get "/devotionals/today"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tomorrow")
    end

    it "redirects to today's published devotional when one exists" do
      d = create(:devotional, :for_today, :published)
      get "/devotionals/today"
      expect(response).to redirect_to(devotional_path(d))
    end

    it "does not redirect when today's devotional is scheduled but unpublished" do
      create(:devotional, :for_today)
      get "/devotionals/today"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tomorrow")
    end
  end

  describe "GET /devotionals/:slug" do
    it "renders a published devotional" do
      d = create(:devotional, :published, :with_body, title: "When the Vision Tarries")
      get devotional_path(d)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("When the Vision Tarries")
    end

    it "404s an unpublished devotional" do
      d = create(:devotional, title: "Draft Word")
      get devotional_path(d)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /devotionals" do
    it "renders the archive index with only published devotionals" do
      published = create(:devotional, :published, title: "Published Morning")
      _draft    = create(:devotional, title: "Draft Morning")
      get devotionals_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(published.title)
      expect(response.body).not_to include("Draft Morning")
    end

    it "filters by tag" do
      waiting = create(:devotional, :published, title: "Waiting Word", tags: %w[waiting])
      story   = create(:devotional, :published, title: "Story Word",   tags: %w[story])
      get devotionals_path(tag: "waiting")
      expect(response.body).to include(waiting.title)
      expect(response.body).not_to include(story.title)
    end
  end
end
