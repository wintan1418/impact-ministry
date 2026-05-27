require "rails_helper"

RSpec.describe Setting, type: :model do
  # The 60-second Rails.cache window means tests that exercise .get must use
  # MemoryStore so cache invalidation actually does something. NullStore (the
  # Rails test default) would otherwise hide stale-read bugs entirely.
  around do |example|
    original_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original_store
  end

  describe "validations" do
    subject { build(:setting) }

    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_uniqueness_of(:key).case_insensitive }
  end

  describe "kind enum" do
    it "defaults to 'string'" do
      expect(Setting.new.kind).to eq("string")
    end

    it "accepts the documented kinds" do
      Setting::KINDS.each do |k|
        expect(build(:setting, kind: k)).to be_valid
      end
    end

    it "rejects unknown kinds via validation" do
      setting = build(:setting, kind: "datetime")
      expect(setting).not_to be_valid
      expect(setting.errors[:kind]).to be_present
    end
  end

  describe ".set / .get" do
    it "stores and reads a string value" do
      Setting.set(:welcome, "Good morning.")
      expect(Setting.get(:welcome)).to eq("Good morning.")
    end

    it "casts boolean kind on read" do
      Setting.set(:prayer_wall_visible, true, kind: "boolean")
      expect(Setting.get(:prayer_wall_visible)).to eq(true)

      Setting.set(:prayer_wall_visible, "false", kind: "boolean")
      expect(Setting.get(:prayer_wall_visible)).to eq(false)
    end

    it "casts integer kind on read" do
      Setting.set(:max_signups, 250, kind: "integer")
      expect(Setting.get(:max_signups)).to eq(250)
    end

    it "casts json kind on read (round-trips hashes and arrays)" do
      Setting.set(:designations, %w[general youth missions], kind: "json")
      expect(Setting.get(:designations)).to eq(%w[general youth missions])

      Setting.set(:hero, { "kicker" => "Today", "title" => "Habakkuk" }, kind: "json")
      expect(Setting.get(:hero)).to eq({ "kicker" => "Today", "title" => "Habakkuk" })
    end

    it "returns nil for unknown keys" do
      expect(Setting.get(:never_set)).to be_nil
    end

    it "updates an existing record rather than duplicating" do
      Setting.set(:greeting, "Hi")
      Setting.set(:greeting, "Hello")
      expect(Setting.where(key: "greeting").count).to eq(1)
      expect(Setting.get(:greeting)).to eq("Hello")
    end
  end

  describe "cache behaviour" do
    it "caches reads under setting:<key>" do
      Setting.set(:cached_key, "first")
      Setting.get(:cached_key)
      expect(Rails.cache.exist?("setting:cached_key")).to be(true)
    end

    it "invalidates the cache on .set" do
      Setting.set(:hero, "old")
      expect(Setting.get(:hero)).to eq("old")

      Setting.set(:hero, "new")
      expect(Setting.get(:hero)).to eq("new")
    end

    it "invalidates the cache on after_save callbacks" do
      record = Setting.set(:rolling, "alpha")
      Setting.get(:rolling) # warm cache

      record.update!(value: "beta")
      expect(Setting.get(:rolling)).to eq("beta")
    end

    it "invalidates the cache on destroy" do
      Setting.set(:goodbye, "see you")
      Setting.get(:goodbye) # warm cache

      Setting.find_by(key: "goodbye").destroy!
      expect(Setting.get(:goodbye)).to be_nil
    end
  end
end
