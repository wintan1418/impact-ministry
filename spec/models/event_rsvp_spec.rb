require "rails_helper"

RSpec.describe EventRsvp, type: :model do
  describe "validations" do
    it "is valid with factory defaults" do
      expect(build(:event_rsvp)).to be_valid
    end

    it "requires a name" do
      r = build(:event_rsvp, name: nil)
      expect(r).not_to be_valid
      expect(r.errors[:name]).to be_present
    end

    it "caps name length at 80" do
      r = build(:event_rsvp, name: "x" * 81)
      expect(r).not_to be_valid
      expect(r.errors[:name]).to be_present
    end

    it "requires a well-formed email" do
      r = build(:event_rsvp, email: "not-an-email")
      expect(r).not_to be_valid
      expect(r.errors[:email]).to be_present
    end

    it "rejects party_size less than 1" do
      r = build(:event_rsvp, party_size: 0)
      expect(r).not_to be_valid
      expect(r.errors[:party_size]).to be_present
    end

    it "rejects party_size greater than 10" do
      r = build(:event_rsvp, party_size: 11)
      expect(r).not_to be_valid
      expect(r.errors[:party_size]).to be_present
    end

    it "enforces case-insensitive uniqueness of email per event" do
      event = create(:event)
      create(:event_rsvp, event: event, email: "ada@example.com")
      dup = build(:event_rsvp, event: event, email: "ADA@example.com")
      expect(dup).not_to be_valid
      expect(dup.errors[:email]).to be_present
    end

    it "lets the same email RSVP to two different events" do
      e1 = create(:event)
      e2 = create(:event)
      create(:event_rsvp, event: e1, email: "ada@example.com")
      second = build(:event_rsvp, event: e2, email: "ada@example.com")
      expect(second).to be_valid
    end
  end

  describe "email normalization" do
    it "strips whitespace and lowercases" do
      r = build(:event_rsvp, email: "  MIX@Example.COM ")
      r.valid?
      expect(r.email).to eq("mix@example.com")
    end
  end

  describe "capacity enforcement" do
    it "blocks an RSVP that would exceed remaining seats" do
      event = create(:event, :capped, capacity: 5)
      create(:event_rsvp, event: event, party_size: 4)
      overflow = build(:event_rsvp, event: event, party_size: 2)

      expect(overflow).not_to be_valid
      expect(overflow.errors[:party_size]).to be_present
    end

    it "allows an RSVP that exactly fills the remaining seats" do
      event = create(:event, :capped, capacity: 5)
      create(:event_rsvp, event: event, party_size: 3)
      last = build(:event_rsvp, event: event, party_size: 2)
      expect(last).to be_valid
    end

    it "ignores capacity when none is set" do
      event = create(:event, capacity: nil)
      r = build(:event_rsvp, event: event, party_size: 9)
      expect(r).to be_valid
    end
  end
end
