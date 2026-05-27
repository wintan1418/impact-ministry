require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /about" do
    it "renders the bespoke about template when the page exists" do
      page = Page.new(title: "About IMPACT Ministry", slug: "about", published: true)
      page.body = "<p>seed body</p>"
      page.save!

      get "/about"

      expect(response).to have_http_status(:ok)
      # Bespoke template-specific content from app/views/pages/about.html.erb.
      expect(response.body).to include("A ministry shaped by")
      expect(response.body).to include("Statement of faith")
    end
  end

  describe "GET /beliefs" do
    it "renders the generic editorial show template" do
      page = Page.new(title: "What we believe", slug: "beliefs", published: true)
      page.body = "<p>The historic Christian confession.</p>"
      page.save!

      get "/beliefs"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("What we believe")
      expect(response.body).to include("The historic Christian confession")
    end
  end

  describe "GET /contact" do
    it "renders the contact page" do
      page = Page.new(title: "Contact us", slug: "contact", published: true)
      page.body = "<p>Write to hello@impactministry.org.</p>"
      page.save!

      get "/contact"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("hello@impactministry.org")
    end
  end

  describe "GET /privacy and /terms" do
    it "renders the privacy page" do
      page = Page.new(title: "Privacy", slug: "privacy", published: true)
      page.body = "<p>We collect as little about you as we can.</p>"
      page.save!

      get "/privacy"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("We collect as little")
    end

    it "renders the terms page" do
      page = Page.new(title: "Terms", slug: "terms", published: true)
      page.body = "<p>Use what we publish freely for personal or church use.</p>"
      page.save!

      get "/terms"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Use what we publish")
    end
  end

  describe "GET /pages/:slug (catch-all)" do
    it "renders a custom editor-created page" do
      page = Page.new(title: "Lent reading guide", published: true)
      page.body = "<p>A six-week walk with the gospel of Mark.</p>"
      page.save!

      get "/pages/#{page.slug}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lent reading guide")
    end
  end

  describe "missing pages" do
    it "returns 404 when the slug doesn't exist" do
      get "/pages/nope-not-here"
      expect(response).to have_http_status(:not_found)
    end

    it "treats unpublished pages as missing" do
      page = Page.new(title: "Draft", slug: "draft", published: false)
      page.body = "<p>not yet</p>"
      page.save!

      get "/pages/draft"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "SEO meta" do
    it "uses the page's description in the meta tag when present" do
      page = Page.new(
        title: "About IMPACT Ministry",
        slug:  "about",
        published: true,
        seo_meta: { "description" => "A short, true word from Mississippi." }
      )
      page.body = "<p>hello</p>"
      page.save!

      get "/about"

      expect(response.body).to include("A short, true word from Mississippi.")
    end
  end
end
