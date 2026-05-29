require "rails_helper"

RSpec.describe Donation, type: :model do
  describe "validations" do
    it "rejects amounts under $1" do
      d = build(:donation, amount_cents: 50)
      expect(d).not_to be_valid
    end

    it "rejects unknown designation at validation time" do
      d = build(:donation, designation: "yacht")
      expect(d).not_to be_valid
      expect(d.errors[:designation]).to be_present
    end

    it "rejects unknown frequency at validation time" do
      d = build(:donation, frequency: "weekly")
      expect(d).not_to be_valid
      expect(d.errors[:frequency]).to be_present
    end
  end

  describe "#amount_formatted" do
    it "renders whole dollars without cents" do
      d = build(:donation, amount_cents: 5_000)
      expect(d.amount_formatted).to eq("$50")
    end

    it "renders dollars + cents for non-whole amounts" do
      d = build(:donation, amount_cents: 5_075)
      expect(d.amount_formatted).to eq("$50.75")
    end
  end

  describe "#designation_label" do
    it "maps to a human label" do
      d = build(:donation, designation: "youth")
      expect(d.designation_label).to eq("Youth")
    end
  end

  describe "#recurring?" do
    it "is true for monthly" do
      d = build(:donation, :monthly)
      expect(d).to be_recurring
    end
  end

  describe "uniqueness" do
    it "rejects duplicate stripe_payment_intent_id" do
      create(:donation, stripe_payment_intent_id: "pi_test_dupe")
      expect { create(:donation, stripe_payment_intent_id: "pi_test_dupe") }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
