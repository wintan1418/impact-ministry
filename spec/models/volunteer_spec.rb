require "rails_helper"

RSpec.describe Volunteer, type: :model do
  describe "validations" do
    it "requires name, email, message" do
      v = Volunteer.new(name: "", email: "", message: "")
      expect(v).not_to be_valid
      expect(v.errors[:name]).to be_present
      expect(v.errors[:email]).to be_present
      expect(v.errors[:message]).to be_present
    end

    it "rejects an invalid email" do
      v = build(:volunteer, email: "not-an-email")
      expect(v).not_to be_valid
    end

    it "rejects unknown interest areas" do
      v = build(:volunteer, interest_areas: %w[writing yacht])
      expect(v).not_to be_valid
      expect(v.errors[:interest_areas].join).to include("yacht")
    end

    it "rejects too-short messages" do
      v = build(:volunteer, message: "hi")
      expect(v).not_to be_valid
    end
  end

  describe "normalization" do
    it "downcases and trims the email" do
      v = create(:volunteer, email: "  MARY@Example.ORG ")
      expect(v.email).to eq("mary@example.org")
    end

    it "uniquifies and trims interest areas" do
      v = create(:volunteer, interest_areas: [ "writing", "", "writing", "prayer" ])
      expect(v.interest_areas).to eq(%w[writing prayer])
    end
  end

  describe "labels" do
    it "renders availability label" do
      v = build(:volunteer, availability: "weeknights")
      expect(v.availability_label).to eq("Weeknights")
    end

    it "renders interests label as bulleted serif" do
      v = build(:volunteer, interest_areas: %w[writing prayer])
      expect(v.interests_label).to eq("Writing · Prayer wall")
    end
  end
end
