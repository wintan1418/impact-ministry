require "rails_helper"

RSpec.describe Partnership, type: :model do
  describe "validations" do
    subject { build(:partnership) }

    it "is valid with factory defaults" do
      expect(subject).to be_valid
    end

    it "requires an organization_name" do
      p = build(:partnership, organization_name: nil)
      expect(p).not_to be_valid
      expect(p.errors[:organization_name]).to be_present
    end

    it "rejects an organization_name longer than 160 characters" do
      p = build(:partnership, organization_name: "a" * 161)
      expect(p).not_to be_valid
      expect(p.errors[:organization_name]).to be_present
    end

    it "requires a contact_name" do
      p = build(:partnership, contact_name: nil)
      expect(p).not_to be_valid
      expect(p.errors[:contact_name]).to be_present
    end

    it "requires a contact_email" do
      p = build(:partnership, contact_email: nil)
      expect(p).not_to be_valid
      expect(p.errors[:contact_email]).to be_present
    end

    it "rejects a malformed contact_email" do
      p = build(:partnership, contact_email: "not-an-email")
      expect(p).not_to be_valid
      expect(p.errors[:contact_email]).to be_present
    end

    it "permits a blank contact_phone" do
      p = build(:partnership, contact_phone: nil)
      expect(p).to be_valid
    end

    it "rejects a contact_phone longer than 40 characters" do
      p = build(:partnership, contact_phone: "1" * 41)
      expect(p).not_to be_valid
      expect(p.errors[:contact_phone]).to be_present
    end

    it "requires a message" do
      p = build(:partnership, message: nil)
      expect(p).not_to be_valid
      expect(p.errors[:message]).to be_present
    end

    it "requires the message to be at least 10 characters" do
      p = build(:partnership, message: "too short")
      expect(p).not_to be_valid
      expect(p.errors[:message]).to be_present
    end

    it "rejects a message longer than 6000 characters" do
      p = build(:partnership, message: "a" * 6001)
      expect(p).not_to be_valid
      expect(p.errors[:message]).to be_present
    end
  end

  describe "organization_type enum" do
    it "defaults to other" do
      expect(Partnership.new.organization_type).to eq("other")
    end

    it "accepts all defined organization_types" do
      Partnership::ORGANIZATION_TYPES.each do |t|
        p = build(:partnership, organization_type: t)
        expect(p).to be_valid, "expected #{t} to be a valid organization_type"
      end
    end

    it "is invalid with an unknown organization_type" do
      p = build(:partnership)
      p[:organization_type] = "alien-civilization"
      expect(p).not_to be_valid
      expect(p.errors[:organization_type]).to be_present
    end
  end

  describe "status enum" do
    it "defaults to new" do
      expect(Partnership.new.status).to eq("new")
    end

    it "accepts all defined statuses" do
      Partnership::STATUSES.each do |s|
        p = build(:partnership, status: s)
        expect(p).to be_valid, "expected #{s} to be a valid status"
      end
    end

    it "is invalid with an unknown status" do
      p = build(:partnership)
      p[:status] = "ghosted"
      expect(p).not_to be_valid
      expect(p.errors[:status]).to be_present
    end
  end

  describe "contact_email normalization" do
    it "strips whitespace and lowercases" do
      p = Partnership.new(contact_email: "  Mixed.Case@Example.COM ")
      expect(p.contact_email).to eq("mixed.case@example.com")
    end
  end

  describe "interest_areas subset validation" do
    it "permits an empty array" do
      p = build(:partnership, interest_areas: [])
      expect(p).to be_valid
    end

    it "permits any single allowed value" do
      Partnership::INTEREST_AREAS.each do |area|
        p = build(:partnership, interest_areas: [ area ])
        expect(p).to be_valid, "expected interest_areas=[#{area}] to be valid"
      end
    end

    it "permits multiple allowed values" do
      p = build(:partnership, interest_areas: %w[devotionals podcast grants])
      expect(p).to be_valid
    end

    it "rejects values outside the allowed set" do
      p = build(:partnership, interest_areas: %w[devotionals magic])
      expect(p).not_to be_valid
      expect(p.errors[:interest_areas].first).to match(/magic/)
    end
  end

  describe "scopes" do
    let!(:fresh_new)  { create(:partnership, :new_status) }
    let!(:reviewing)  { create(:partnership, :in_review) }
    let!(:engaged)    { create(:partnership, :engaged) }
    let!(:declined)   { create(:partnership, :declined) }

    describe ".unread" do
      it "returns only status=new partnerships" do
        expect(Partnership.unread).to contain_exactly(fresh_new)
      end
    end

    describe ".recent_first" do
      it "orders newest first" do
        ordered = Partnership.recent_first.to_a
        expect(ordered.first.created_at).to be >= ordered.last.created_at
      end
    end
  end

  describe "#kind_label" do
    it "returns a friendly label for known types" do
      expect(build(:partnership, :church).kind_label).to eq("Church")
      expect(build(:partnership, :nonprofit).kind_label).to eq("Nonprofit")
      expect(build(:partnership, :business).kind_label).to eq("Business")
    end
  end

  describe "#interests_label" do
    it "joins interest areas with ' · '" do
      p = build(:partnership, interest_areas: %w[devotionals podcast])
      expect(p.interests_label).to eq("Devotionals · Podcast")
    end

    it "returns an empty string when none selected" do
      p = build(:partnership, interest_areas: [])
      expect(p.interests_label).to eq("")
    end
  end

  describe "#to_s" do
    it "returns the organization_name" do
      p = build(:partnership, organization_name: "Cedar Grove Church")
      expect(p.to_s).to eq("Cedar Grove Church")
    end
  end
end
