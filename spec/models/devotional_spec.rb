require "rails_helper"

RSpec.describe Devotional, type: :model do
  describe "validations" do
    it "is valid with the factory defaults" do
      expect(build(:devotional)).to be_valid
    end

    it "requires a title" do
      d = build(:devotional, title: nil)
      expect(d).not_to be_valid
      expect(d.errors[:title]).to be_present
    end

    it "requires a scripture_reference" do
      d = build(:devotional, scripture_reference: nil)
      expect(d).not_to be_valid
      expect(d.errors[:scripture_reference]).to be_present
    end

    it "requires a scheduled_for date" do
      d = build(:devotional, scheduled_for: nil)
      expect(d).not_to be_valid
      expect(d.errors[:scheduled_for]).to be_present
    end

    it "requires an author" do
      d = build(:devotional, author: nil)
      expect(d).not_to be_valid
      expect(d.errors[:author]).to be_present
    end

    it "enforces uniqueness of scheduled_for" do
      date = Date.current + 5.days
      create(:devotional, scheduled_for: date)
      duplicate = build(:devotional, scheduled_for: date)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:scheduled_for]).to be_present
    end
  end

  describe "friendly_id slug generation" do
    it "generates a slug from the title on create" do
      d = create(:devotional, title: "When the Vision Tarries")
      expect(d.slug).to be_present
      expect(d.slug).to include("when-the-vision-tarries")
    end

    it "regenerates the slug if the title changes" do
      d = create(:devotional, title: "First Title")
      original_slug = d.slug
      d.update!(title: "A Completely Different Title")
      expect(d.slug).not_to eq(original_slug)
      expect(d.slug).to include("completely-different-title")
    end
  end

  describe "#published? and #publish!" do
    it "is unpublished by default" do
      d = create(:devotional)
      expect(d.published?).to be(false)
    end

    it "is published once published_at is set" do
      d = create(:devotional, :published)
      expect(d.published?).to be(true)
    end

    it "#publish! sets published_at to now" do
      d = create(:devotional)
      freeze_time do
        d.publish!
        expect(d.published_at).to eq(Time.current)
      end
    end

    it "#publish! is a no-op if already published" do
      original = 2.days.ago
      d = create(:devotional, published_at: original)
      d.publish!
      expect(d.published_at).to be_within(1.second).of(original)
    end
  end

  describe "scopes" do
    it ".published returns only devotionals with published_at" do
      published = create(:devotional, :published)
      _scheduled = create(:devotional)
      expect(Devotional.published).to contain_exactly(published)
    end

    it ".scheduled returns only devotionals without published_at" do
      _published = create(:devotional, :published)
      scheduled = create(:devotional)
      expect(Devotional.scheduled).to contain_exactly(scheduled)
    end

    it ".for_today returns devotionals scheduled for today" do
      today_one = create(:devotional, scheduled_for: Date.current)
      _tomorrow = create(:devotional, scheduled_for: Date.current + 1.day)
      expect(Devotional.for_today).to contain_exactly(today_one)
    end

    it ".recent_first orders by scheduled_for desc" do
      old = create(:devotional, scheduled_for: Date.current + 1.day)
      new = create(:devotional, scheduled_for: Date.current + 10.days)
      expect(Devotional.recent_first.first).to eq(new)
      expect(Devotional.recent_first.last).to eq(old)
    end

    it ".tagged filters by a tag in the array" do
      waiting = create(:devotional, tags: %w[waiting comfort])
      _other  = create(:devotional, tags: %w[story])
      expect(Devotional.tagged("waiting")).to contain_exactly(waiting)
    end
  end

  describe "pg_search .search_text" do
    it "matches by title" do
      match = create(:devotional, title: "When the Vision Tarries", scripture_reference: "Habakkuk 2:1")
      _other = create(:devotional, title: "The Bread of Tomorrow", scripture_reference: "Matthew 6:11")
      expect(Devotional.search_text("Vision")).to include(match)
    end

    it "matches by scripture_reference" do
      match = create(:devotional, title: "Some title", scripture_reference: "Habakkuk 2:1")
      _other = create(:devotional, title: "Another title", scripture_reference: "Psalm 23")
      expect(Devotional.search_text("Habakkuk")).to include(match)
    end
  end

  describe "#tomorrow" do
    it "returns the devotional scheduled for the next day" do
      today_d    = create(:devotional, scheduled_for: Date.current)
      tomorrow_d = create(:devotional, scheduled_for: Date.current + 1.day)
      expect(today_d.tomorrow).to eq(tomorrow_d)
    end

    it "returns nil when no devotional is scheduled for tomorrow" do
      today_d = create(:devotional, scheduled_for: Date.current)
      expect(today_d.tomorrow).to be_nil
    end
  end

  describe "ActionText body" do
    it "stores and returns rich text body content" do
      d = create(:devotional, :with_body)
      expect(d.body).to be_present
      expect(d.body.to_plain_text).to include("Habakkuk")
    end
  end
end
