require "rails_helper"

RSpec.describe "Testimonies", type: :request do
  describe "GET /testimonies" do
    it "renders the wall with only approved testimonies" do
      approved = create(:testimony, :approved, body: "He met me on a Tuesday morning. I have never been the same.")
      _pending = create(:testimony, body: "This story is still in moderation and should not appear.")

      get "/testimonies"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Real change")
      expect(response.body).to include(approved.pull_quote)
      expect(response.body).not_to include("still in moderation")
    end

    it "renders featured testimonies in the featured row" do
      featured = create(:testimony, :featured, body: "The morning email found me at the kitchen table. I'd forgotten how to ask.")

      get "/testimonies"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Featured")
      expect(response.body).to include(featured.pull_quote)
    end

    it "renders an empty-wall message when there are no approved testimonies" do
      get "/testimonies"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("The wall is quiet")
    end
  end

  describe "GET /testify" do
    it "renders the submission form" do
      get "/testify"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tell us what God did")
      expect(response.body).to include('id="testimony-form"')
      expect(response.body).to include("Share your story")
    end
  end

  describe "POST /testimonies" do
    let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
    let(:valid_attrs) do
      {
        testimony: {
          name: "Marcus L.",
          location: "Jackson, MS",
          body: "I hadn't opened a Bible in nine years. The morning email didn't ask me to. It just showed up."
        }
      }
    end

    it "creates an unapproved testimony and renders a Turbo Stream thank-you" do
      expect {
        post "/testimonies", params: valid_attrs, headers: turbo_headers
      }.to change(Testimony, :count).by(1)

      t = Testimony.last
      expect(t.name).to eq("Marcus L.")
      expect(t.location).to eq("Jackson, MS")
      expect(t.approved).to be false
      expect(t.featured).to be false
      expect(t.submitted_at).to be_present

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to include("turbo-stream")
      expect(response.body).to include("testimony-form")
      expect(response.body).to include("Thank you")
    end

    it "ignores client-supplied approved/featured params" do
      attrs = valid_attrs.deep_merge(testimony: { approved: true, featured: true })

      post "/testimonies", params: attrs, headers: turbo_headers

      t = Testimony.last
      expect(t.approved).to be false
      expect(t.featured).to be false
    end

    it "accepts an anonymous submission (no name)" do
      attrs = valid_attrs.deep_merge(testimony: { name: "" })

      expect {
        post "/testimonies", params: attrs, headers: turbo_headers
      }.to change(Testimony, :count).by(1)

      expect(Testimony.last.display_name).to eq("A friend")
      expect(response).to have_http_status(:ok)
    end

    it "re-renders the form with an inline error when the body is too short" do
      attrs = valid_attrs.deep_merge(testimony: { body: "too short" })

      expect {
        post "/testimonies", params: attrs, headers: turbo_headers
      }.not_to change(Testimony, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("testimony-form")
      expect(response.body).to include("Body")
      expect(response.body).not_to include("Thank you")
    end

    it "renders an inline turnstile failure when verification is forced to fail" do
      attrs = valid_attrs.merge("cf-turnstile-response" => "FORCE_FAIL")

      expect {
        post "/testimonies", params: attrs, headers: turbo_headers
      }.not_to change(Testimony, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("testimony-form")
      expect(response.body).to include("couldn&#39;t verify").or include("couldn't verify")
    end

    it "accepts an attached photo upload" do
      file = Rack::Test::UploadedFile.new(StringIO.new("fake-jpg-bytes"), "image/jpeg", original_filename: "story.jpg")
      attrs = valid_attrs.deep_merge(testimony: { photo: file })

      expect {
        post "/testimonies", params: attrs, headers: turbo_headers
      }.to change(Testimony, :count).by(1)

      expect(Testimony.last.photo).to be_attached
    end
  end
end
