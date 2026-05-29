require "rails_helper"

RSpec.describe "Account donations", type: :request do
  let(:user) { create(:user, :confirmed, password: "secret123") }

  def sign_in_as(u)
    post session_path, params: { email_address: u.email_address, password: "secret123" }
  end

  describe "GET /account/donations" do
    it "redirects unauthenticated users to sign in" do
      get account_donations_path
      expect(response).to redirect_to(new_session_path)
    end

    it "renders empty state when the signed-in user has no donor row" do
      sign_in_as(user)
      get account_donations_path
      expect(response.body).to include("No gifts on file")
    end

    it "lists donations for the signed-in user" do
      sign_in_as(user)
      donor = create(:donor, user: user, email: user.email_address)
      create(:donation, donor: donor, amount_cents: 10_000, designation: "youth")
      get account_donations_path
      expect(response.body).to include("$100")
      expect(response.body).to include("Youth")
    end
  end

  describe "POST /account/donations/portal" do
    it "redirects to Stripe Billing Portal when the donor has a stripe customer id" do
      sign_in_as(user)
      donor = create(:donor, :with_stripe, user: user, email: user.email_address)
      portal_url = "https://billing.stripe.test/p_test"
      allow(Stripe::BillingPortal::Session).to receive(:create).and_return(
        Stripe::StripeObject.construct_from(url: portal_url)
      )

      post account_donations_portal_path
      expect(response).to redirect_to(portal_url)
    end

    it "redirects back with a flash when there is no donor row" do
      sign_in_as(user)
      post account_donations_portal_path
      expect(response).to redirect_to(account_donations_path)
      expect(flash[:alert]).to include("billing portal")
    end
  end
end
