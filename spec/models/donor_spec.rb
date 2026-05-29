require "rails_helper"

RSpec.describe Donor, type: :model do
  it "normalizes email to lowercase" do
    d = create(:donor, email: "MIXED@Case.Org")
    expect(d.email).to eq("mixed@case.org")
  end

  it "requires email" do
    d = Donor.new(email: nil)
    expect(d).not_to be_valid
  end

  it "enforces uniqueness on stripe_customer_id when present" do
    create(:donor, :with_stripe, stripe_customer_id: "cus_test_dupe")
    dup = build(:donor, stripe_customer_id: "cus_test_dupe")
    expect(dup).not_to be_valid
  end

  it "allows nil stripe_customer_id on multiple donors" do
    create(:donor, stripe_customer_id: nil)
    expect { create(:donor, stripe_customer_id: nil) }.not_to raise_error
  end

  describe "#display_name" do
    it "prefers name over email" do
      d = build(:donor, name: "Mary R", email: "m@example.com")
      expect(d.display_name).to eq("Mary R")
    end

    it "falls back to email when name is blank" do
      d = build(:donor, name: "", email: "m@example.com")
      expect(d.display_name).to eq("m@example.com")
    end
  end
end
