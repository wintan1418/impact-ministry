require "rails_helper"

RSpec.describe "Account", type: :request do
  let(:author)     { create(:user, :admin) }
  let(:subscriber) { create(:user, :confirmed, password: "secret123") }

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /account (no auth)" do
    it "redirects to the sign-in page" do
      get account_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /users/new" do
    it "renders the sign-up form" do
      get new_user_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/Start your.*reading streak/m)
    end
  end

  describe "POST /users" do
    it "creates a subscriber and signs them in" do
      expect {
        post users_path, params: { user: {
          name: "New Reader",
          email_address: "new-reader@example.com",
          password: "secret123",
          password_confirmation: "secret123"
        } }
      }.to change(User, :count).by(1)

      user = User.find_by(email_address: "new-reader@example.com")
      expect(user).to be_present
      expect(user.role).to eq("subscriber")
      expect(user).to be_confirmed
      expect(response).to redirect_to(account_path)
    end

    it "re-renders with errors on invalid input" do
      post users_path, params: { user: {
        name: "",
        email_address: "not-an-email",
        password: "x",
        password_confirmation: "y"
      } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "authenticated /account flow" do
    before { sign_in_as(subscriber) }

    it "GET /account renders the dashboard with streak data" do
      subscriber.update!(current_streak: 5, longest_streak: 10, last_read_on: Date.current)
      get account_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Reading streak")
      expect(response.body).to include("5")
    end

    it "GET /account/highlights renders the (possibly empty) collection" do
      get account_highlights_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Your highlights")
    end

    it "GET /account/settings renders the settings form" do
      get account_settings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Settings")
    end

    it "PATCH /account/settings updates the user's name" do
      patch account_settings_path, params: { user: { name: "Renamed Reader" } }
      expect(response).to redirect_to(account_settings_path)
      expect(subscriber.reload.name).to eq("Renamed Reader")
    end
  end
end
