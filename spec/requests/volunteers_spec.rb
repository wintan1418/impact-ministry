require "rails_helper"

RSpec.describe "Volunteers", type: :request do
  describe "GET /volunteer" do
    it "renders the editorial intake hero + form" do
      get volunteer_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bring your gifts")
      expect(response.body).to include("Where you can plug in")
    end
  end

  describe "POST /volunteer" do
    let(:valid_params) do
      {
        volunteer: {
          name: "Mary R",
          email: "mary@example.com",
          phone: "601-555-0123",
          availability: "flexible",
          interest_areas: [ "", "writing", "prayer" ],
          gifts: "Some background in copyediting.",
          message: "I'd love to help with the morning devotional series whenever I can."
        }
      }
    end

    it "creates a volunteer and enqueues the notification" do
      expect {
        post volunteer_path, params: valid_params
      }.to change(Volunteer, :count).by(1)
        .and have_enqueued_job(VolunteerNotificationJob)

      expect(response).to redirect_to(volunteer_path)
    end

    it "responds with a turbo stream when requested" do
      post volunteer_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Thank you")
    end

    it "re-renders the form with inline errors on invalid input" do
      bad = valid_params.deep_dup
      bad[:volunteer][:email] = ""
      bad[:volunteer][:message] = "hi"
      expect {
        post volunteer_path, params: bad, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.not_to change(Volunteer, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
