require "rails_helper"

RSpec.describe Giving::CreateCheckoutSession do
  let(:base) do
    {
      amount_cents: 5_000,
      frequency: "once",
      designation: "general",
      email: "donor@example.com",
      name: "Mary",
      success_url: "https://example.com/give/thanks",
      cancel_url: "https://example.com/give"
    }
  end

  before do
    allow(Stripe::Checkout::Session).to receive(:create).and_return(
      Stripe::StripeObject.construct_from(id: "cs_test_abc", url: "https://stripe.test/cs_test_abc")
    )
  end

  it "calls Stripe with payment mode for one-time" do
    described_class.call(**base)
    expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(mode: "payment"))
  end

  it "calls Stripe with subscription mode for monthly" do
    described_class.call(**base.merge(frequency: "monthly"))
    expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(mode: "subscription"))
  end

  it "returns a success Result with the Stripe URL" do
    result = described_class.call(**base)
    expect(result).to be_success
    expect(result.value.url).to start_with("https://stripe.test/")
  end

  it "fails on a sub-$1 amount" do
    result = described_class.call(**base.merge(amount_cents: 50))
    expect(result).to be_failure
    expect(result.error).to match(/gift amount/i)
  end

  it "fails on a bad email" do
    result = described_class.call(**base.merge(email: "not-an-email"))
    expect(result).to be_failure
  end

  it "fails on an unknown designation" do
    result = described_class.call(**base.merge(designation: "yacht"))
    expect(result).to be_failure
  end

  it "translates Stripe errors into a result failure" do
    allow(Stripe::Checkout::Session).to receive(:create).and_raise(Stripe::APIError.new("upstream down"))
    result = described_class.call(**base)
    expect(result).to be_failure
    expect(result.error).to match(/Stripe/)
  end

  it "passes designation in metadata so the webhook can recover it" do
    described_class.call(**base.merge(designation: "youth"))
    expect(Stripe::Checkout::Session).to have_received(:create).with(
      hash_including(metadata: hash_including(designation: "youth"))
    )
  end
end
