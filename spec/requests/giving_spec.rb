require "rails_helper"

RSpec.describe "Giving", type: :request do
  describe "GET /give" do
    it "renders the placeholder when GIVING_ENABLED is false" do
      original = ENV["GIVING_ENABLED"]
      ENV["GIVING_ENABLED"] = "false"
      begin
        get give_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("A place is being prepared")
        expect(response.body).not_to include("Continue to Stripe")
      ensure
        ENV["GIVING_ENABLED"] = original
      end
    end

    it "renders the live form when GIVING_ENABLED is true" do
      original = ENV["GIVING_ENABLED"]
      ENV["GIVING_ENABLED"] = "true"
      begin
        get give_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Continue to Stripe")
        expect(response.body).to include("General Fund")
      ensure
        ENV["GIVING_ENABLED"] = original
      end
    end
  end

  describe "POST /give" do
    around do |ex|
      original = ENV["GIVING_ENABLED"]
      ENV["GIVING_ENABLED"] = "true"
      ex.run
      ENV["GIVING_ENABLED"] = original
    end

    it "redirects to the Stripe Checkout URL on success" do
      stripe_url = "https://checkout.stripe.test/cs_test_abc"
      allow(Stripe::Checkout::Session).to receive(:create).and_return(
        Stripe::StripeObject.construct_from(id: "cs_test_abc", url: stripe_url)
      )

      post give_path, params: {
        amount: "25",
        frequency: "once",
        designation: "general",
        email: "donor@example.com",
        donor_name: "Mary R"
      }

      expect(response).to redirect_to(stripe_url)
    end

    it "re-renders the form with the error on validation failure" do
      post give_path, params: {
        amount: "0",
        frequency: "once",
        designation: "general",
        email: "donor@example.com"
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Continue to Stripe")
    end

    it "blocks POST when GIVING_ENABLED is off" do
      original = ENV["GIVING_ENABLED"]
      ENV["GIVING_ENABLED"] = "false"
      begin
        post give_path, params: { amount: "25" }
        expect(response).to redirect_to(give_path)
      ensure
        ENV["GIVING_ENABLED"] = original
      end
    end
  end

  describe "GET /give/thanks" do
    it "renders the quiet thank-you page" do
      get give_thanks_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Thank you")
    end
  end
end
