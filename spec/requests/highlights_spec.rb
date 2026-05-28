require "rails_helper"

RSpec.describe "Highlights", type: :request do
  let(:subscriber) { create(:user, :confirmed, password: "secret123") }
  let(:author)     { create(:user, :admin) }
  let(:devotional) { create(:devotional, :published, :with_body, author: author) }

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "POST /highlights" do
    it "requires authentication" do
      post highlights_path, params: { devotional_id: devotional.id, text_range: '{"text":"x"}' }
      expect(response).to redirect_to(new_session_path)
    end

    it "creates a highlight for the signed-in user" do
      sign_in_as(subscriber)
      payload = { start: 10, end: 60, text: "A line that stopped me." }.to_json

      expect {
        post highlights_path,
             params: { devotional_id: devotional.id, text_range: payload },
             headers: { "Accept" => "application/json" }
      }.to change(DevotionalHighlight, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(subscriber.devotional_highlights.last.excerpt).to include("A line that stopped me.")
    end
  end

  describe "DELETE /highlights/:id" do
    let!(:highlight) {
      create(:user).tap { |u|
        # Owned by a different user — should not be removable by subscriber.
      }
      DevotionalHighlight.create!(
        user: subscriber,
        devotional: devotional,
        text_range: { text: "Mine." }.to_json
      )
    }

    it "removes the user's highlight" do
      sign_in_as(subscriber)
      expect {
        delete highlight_path(highlight), headers: { "Accept" => "application/json" }
      }.to change(DevotionalHighlight, :count).by(-1)
    end

    it "refuses to remove someone else's highlight" do
      other = create(:user, :confirmed, password: "secret123")
      other_highlight = DevotionalHighlight.create!(
        user: other,
        devotional: devotional,
        text_range: { text: "Not yours." }.to_json
      )

      sign_in_as(subscriber)
      expect {
        delete highlight_path(other_highlight), headers: { "Accept" => "application/json" }
      }.not_to change(DevotionalHighlight, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
