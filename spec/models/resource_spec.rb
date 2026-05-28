require "rails_helper"

RSpec.describe Resource, type: :model do
  describe "validations" do
    it "is valid with the factory defaults" do
      expect(build(:resource)).to be_valid
    end

    it "requires a title" do
      r = build(:resource, title: nil)
      expect(r).not_to be_valid
      expect(r.errors[:title]).to be_present
    end

    it "rejects an unknown category" do
      r = build(:resource)
      r.category = "not_a_real_one"
      expect(r).not_to be_valid
      expect(r.errors[:category]).to be_present
    end

    it "enforces slug uniqueness" do
      create(:resource, title: "Reading the Psalms Slowly")
      duplicate = build(:resource, title: "Reading the Psalms Slowly")
      duplicate.valid?
      # friendly_id will append a uuid suffix to keep it unique, so it should be valid.
      expect(duplicate).to be_valid
      expect(duplicate.slug).not_to eq(Resource.first.slug)
    end
  end

  describe "friendly_id slug generation" do
    it "generates a slug from the title on create" do
      r = create(:resource, title: "Three Sermons on Waiting")
      expect(r.slug).to be_present
      expect(r.slug).to include("three-sermons-on-waiting")
    end

    it "regenerates the slug if the title changes" do
      r = create(:resource, title: "First Title")
      original = r.slug
      r.update!(title: "A Completely Different Title")
      expect(r.slug).not_to eq(original)
      expect(r.slug).to include("completely-different-title")
    end
  end

  describe "category enum" do
    it "exposes a label that humanizes underscored names" do
      r = build(:resource, category: "devotional_collection")
      expect(r.category_label).to eq("Devotional Collection")
    end

    Resource::CATEGORIES.each do |cat|
      it "accepts the '#{cat}' category" do
        expect(build(:resource, category: cat)).to be_valid
      end
    end
  end

  describe "scopes" do
    it ".published returns only resources with published_at" do
      published = create(:resource, :published)
      _draft    = create(:resource)
      expect(Resource.published).to contain_exactly(published)
    end

    it ".featured returns only featured resources" do
      featured = create(:resource, :featured)
      _plain   = create(:resource)
      expect(Resource.featured).to contain_exactly(featured)
    end

    it ".recent_first orders by published_at desc" do
      older = create(:resource, :published, published_at: 10.days.ago)
      newer = create(:resource, :published, published_at: 1.day.ago)
      expect(Resource.recent_first.first).to eq(newer)
      expect(Resource.recent_first.last).to eq(older)
    end

    it ".by_category filters by a single category" do
      guide  = create(:resource, category: "guide")
      sermon = create(:resource, category: "sermon")
      expect(Resource.by_category("guide")).to contain_exactly(guide)
      expect(Resource.by_category("sermon")).to contain_exactly(sermon)
    end
  end

  describe "#published? and #publish!" do
    it "is unpublished by default" do
      expect(create(:resource).published?).to be(false)
    end

    it "is published once published_at is set" do
      expect(create(:resource, :published).published?).to be(true)
    end

    it "#publish! sets published_at to now" do
      r = create(:resource)
      freeze_time do
        r.publish!
        expect(r.published_at).to eq(Time.current)
      end
    end

    it "#publish! is a no-op if already published" do
      original = 2.days.ago
      r = create(:resource, published_at: original)
      r.publish!
      expect(r.published_at).to be_within(1.second).of(original)
    end
  end

  describe "#increment_downloads!" do
    it "atomically increments the counter" do
      r = create(:resource, :published, downloads_count: 5)
      r.increment_downloads!
      expect(r.downloads_count).to eq(6)
    end

    it "increments via SQL — concurrent updates do not lose writes" do
      r = create(:resource, :published, downloads_count: 0)
      # Simulate two concurrent in-memory copies; counter_cache-style increment
      # writes via UPDATE … SET downloads_count = downloads_count + 1.
      a = Resource.find(r.id)
      b = Resource.find(r.id)
      a.increment_downloads!
      b.increment_downloads!
      expect(r.reload.downloads_count).to eq(2)
    end
  end

  describe "pg_search .search_text" do
    it "matches by title" do
      match = create(:resource, :published, title: "30 Days of Habakkuk", description: "A printable devotional companion.")
      _other = create(:resource, :published, title: "Reading the Psalms Slowly", description: "Notes for four weeks.")
      expect(Resource.search_text("Habakkuk")).to include(match)
    end

    it "matches by description" do
      match = create(:resource, :published, title: "Quiet Mornings", description: "Notes on praying when you don't feel it.")
      _other = create(:resource, :published, title: "Another Title", description: "Different prose entirely.")
      expect(Resource.search_text("praying")).to include(match)
    end
  end

  describe "ActiveStorage file" do
    it "accepts an attached file" do
      r = create(:resource, :with_file)
      expect(r.file).to be_attached
      expect(r.file.filename.to_s).to eq("sample_resource.pdf")
    end
  end
end
