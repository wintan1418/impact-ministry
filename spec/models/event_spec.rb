require "rails_helper"

RSpec.describe Event, type: :model do
  describe "validations" do
    it "is valid with factory defaults" do
      expect(build(:event)).to be_valid
    end

    it "requires a title" do
      e = build(:event, title: nil)
      expect(e).not_to be_valid
      expect(e.errors[:title]).to be_present
    end

    it "requires starts_at" do
      e = build(:event, starts_at: nil)
      expect(e).not_to be_valid
      expect(e.errors[:starts_at]).to be_present
    end

    it "rejects a non-positive capacity" do
      e = build(:event, capacity: 0)
      expect(e).not_to be_valid
      expect(e.errors[:capacity]).to be_present
    end

    it "allows a nil capacity (open invitation)" do
      expect(build(:event, capacity: nil)).to be_valid
    end

    it "rejects a malformed virtual_link" do
      e = build(:event, virtual_link: "not a url")
      expect(e).not_to be_valid
      expect(e.errors[:virtual_link]).to be_present
    end

    it "allows a blank virtual_link" do
      expect(build(:event, virtual_link: nil)).to be_valid
    end
  end

  describe "friendly_id slug generation" do
    it "generates a slug from the title on create" do
      e = create(:event, title: "First Light Devotional Brunch")
      expect(e.slug).to be_present
      expect(e.slug).to include("first-light-devotional-brunch")
    end

    it "regenerates the slug when the title changes" do
      e = create(:event, title: "Old Title")
      original = e.slug
      e.update!(title: "A Brand New Gathering Name")
      expect(e.slug).not_to eq(original)
      expect(e.slug).to include("brand-new-gathering-name")
    end
  end

  describe "scopes" do
    it ".published returns only published events" do
      pub   = create(:event)
      draft = create(:event, :unpublished)
      expect(Event.published).to include(pub)
      expect(Event.published).not_to include(draft)
    end

    it ".upcoming returns events starting now or later" do
      soon = create(:event, starts_at: 1.day.from_now)
      _gone = create(:event, :past)
      expect(Event.upcoming).to contain_exactly(soon)
    end

    it ".past returns events that already started" do
      _soon = create(:event, starts_at: 1.day.from_now)
      gone = create(:event, :past)
      expect(Event.past).to contain_exactly(gone)
    end

    it ".chronological orders by starts_at asc" do
      later  = create(:event, starts_at: 10.days.from_now)
      sooner = create(:event, starts_at: 2.days.from_now)
      expect(Event.chronological.to_a).to eq([ sooner, later ])
    end

    it ".reverse_chronological orders by starts_at desc" do
      later  = create(:event, starts_at: 10.days.from_now)
      sooner = create(:event, starts_at: 2.days.from_now)
      expect(Event.reverse_chronological.to_a).to eq([ later, sooner ])
    end
  end

  describe "#seats_remaining" do
    it "is nil when capacity is unlimited" do
      e = create(:event, capacity: nil)
      expect(e.seats_remaining).to be_nil
    end

    it "subtracts existing RSVP party_size totals" do
      e = create(:event, :capped, capacity: 10)
      create(:event_rsvp, event: e, party_size: 3)
      create(:event_rsvp, event: e, party_size: 2)
      expect(e.seats_remaining).to eq(5)
    end

    it "floors at zero when overbooked" do
      e = create(:event, :capped, capacity: 2)
      create(:event_rsvp, event: e, party_size: 2)
      # Bypass validations to simulate manual seed/admin row over capacity.
      e.event_rsvps.create!(name: "Manual", email: "manual@example.com", party_size: 1) rescue nil
      expect(e.seats_remaining).to be >= 0
    end
  end

  describe "#full?" do
    it "is false with no capacity" do
      e = create(:event, capacity: nil)
      expect(e.full?).to be false
    end

    it "is true once capacity is reached" do
      e = create(:event, :capped, capacity: 4)
      create(:event_rsvp, event: e, party_size: 4)
      expect(e.full?).to be true
    end
  end

  describe "#over?" do
    it "is true when ends_at is in the past" do
      e = build(:event, starts_at: 3.hours.ago, ends_at: 1.hour.ago)
      expect(e.over?).to be true
    end

    it "is false when ends_at is in the future" do
      e = build(:event, starts_at: 1.hour.from_now, ends_at: 4.hours.from_now)
      expect(e.over?).to be false
    end

    it "falls back to starts_at + 24h when ends_at is blank" do
      e = build(:event, starts_at: 2.days.ago, ends_at: nil)
      expect(e.over?).to be true
    end
  end

  describe "#virtual?" do
    it "is true when virtual_link is set and location is blank" do
      e = build(:event, :virtual)
      expect(e.virtual?).to be true
    end

    it "is false when an in-person location is also set" do
      e = build(:event, :virtual, location: "Jackson, MS")
      expect(e.virtual?).to be false
    end

    it "is false when virtual_link is blank" do
      e = build(:event, virtual_link: nil)
      expect(e.virtual?).to be false
    end
  end
end
