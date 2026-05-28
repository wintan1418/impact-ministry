require "rails_helper"

RSpec.describe "Resources", type: :request do
  describe "GET /resources" do
    it "renders the index with featured + per-category sections" do
      featured = create(:resource, :published, :featured, title: "30 Days of Habakkuk", category: "devotional_collection")
      sermon   = create(:resource, :published, title: "Three Sermons on Waiting", category: "sermon")
      _draft   = create(:resource, title: "Unpublished Notes")

      get "/resources"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(featured.title)
      expect(response.body).to include(sermon.title)
      expect(response.body).not_to include("Unpublished Notes")
    end

    it "filters by category" do
      guide  = create(:resource, :published, title: "Quiet Mornings Guide", category: "guide")
      sermon = create(:resource, :published, title: "Sermons on Waiting",   category: "sermon")

      get "/resources", params: { category: "guide" }

      expect(response.body).to include(guide.title)
      expect(response.body).not_to include(sermon.title)
    end

    it "supports a search query" do
      match  = create(:resource, :published, title: "Reading the Psalms Slowly", description: "A four-week guide.")
      _other = create(:resource, :published, title: "Bread for the Day",         description: "A short morning note.")

      get "/resources", params: { q: "Psalms" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(match.title)
    end

    it "renders the empty state when nothing is published" do
      get "/resources"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("More resources are on the way")
    end
  end

  describe "GET /resources/:slug" do
    it "renders a published resource with its download gate form" do
      resource = create(:resource, :published, title: "30 Days of Habakkuk", requires_email: true)

      get "/resources/#{resource.slug}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(resource.title)
      expect(response.body).to include("resource-download-#{resource.id}")
      expect(response.body).to include("Send it to me")
    end

    it "shows the direct download button when no email is required" do
      resource = create(:resource, :published, :no_email_gate, title: "Mississippi Morning Playlist")

      get "/resources/#{resource.slug}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Download now")
    end

    it "404s an unpublished resource" do
      resource = create(:resource, title: "Hidden Draft")

      get "/resources/#{resource.slug}"

      expect(response).to have_http_status(:not_found)
    end

    it "404s an unknown slug" do
      get "/resources/does-not-exist"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /resources/:slug/download (email-gated)" do
    it "creates a new EmailSubscriber with source='resource_download'" do
      resource = create(:resource, :published, :with_file, title: "30 Days of Habakkuk", requires_email: true)

      expect {
        post "/resources/#{resource.slug}/download",
             params: { email: "reader@example.com", name: "Reader" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(EmailSubscriber, :count).by(1)

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      sub = EmailSubscriber.find_by(email: "reader@example.com")
      expect(sub.source).to eq("resource_download")
    end

    it "increments downloads_count by 1" do
      resource = create(:resource, :published, :with_file, requires_email: true, downloads_count: 4)

      post "/resources/#{resource.slug}/download",
           params: { email: "reader@example.com" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(resource.reload.downloads_count).to eq(5)
    end

    it "responds with a turbo stream that swaps in the download_ready frame" do
      resource = create(:resource, :published, :with_file, title: "Cover the Roads", requires_email: true)

      post "/resources/#{resource.slug}/download",
           params: { email: "reader@example.com" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include("resource-download-#{resource.id}")
      expect(response.body).to include("The download should start in a moment")
    end

    it "is idempotent for an existing active subscriber (no duplicate row, no source overwrite)" do
      create(:email_subscriber, email: "already@example.com", source: "footer")
      resource = create(:resource, :published, requires_email: true)

      expect {
        post "/resources/#{resource.slug}/download",
             params: { email: "already@example.com" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.not_to change(EmailSubscriber, :count)

      expect(EmailSubscriber.find_by(email: "already@example.com").source).to eq("footer")
      expect(resource.reload.downloads_count).to eq(1)
    end

    it "re-renders the gate form with an error on a bad email" do
      resource = create(:resource, :published, requires_email: true)

      post "/resources/#{resource.slug}/download",
           params: { email: "not-an-email" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Please enter a valid email")
      expect(response.body).to include("resource-download-#{resource.id}")
    end

    it "re-renders the gate form when turnstile verification fails" do
      resource = create(:resource, :published, requires_email: true)

      post "/resources/#{resource.slug}/download",
           params: { email: "reader@example.com", "cf-turnstile-response" => "FORCE_FAIL" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("verify you")
      expect(response.body).to include("human")
    end
  end

  describe "POST /resources/:slug/download (open / no email required)" do
    it "redirects to the file blob on HTML" do
      resource = create(:resource, :published, :no_email_gate, :with_file, title: "Free Audio")

      post "/resources/#{resource.slug}/download"

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("sample_resource.pdf")
    end

    it "increments downloads_count without creating a subscriber" do
      resource = create(:resource, :published, :no_email_gate, :with_file, downloads_count: 10)

      expect {
        post "/resources/#{resource.slug}/download"
      }.not_to change(EmailSubscriber, :count)

      expect(resource.reload.downloads_count).to eq(11)
    end
  end
end
