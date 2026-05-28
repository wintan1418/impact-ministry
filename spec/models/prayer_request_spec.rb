require "rails_helper"

RSpec.describe PrayerRequest, type: :model do
  describe "validations" do
    subject { build(:prayer_request) }

    it "is valid with factory defaults" do
      expect(subject).to be_valid
    end

    it "requires a body" do
      pr = build(:prayer_request, body: nil)
      expect(pr).not_to be_valid
      expect(pr.errors[:body]).to be_present
    end

    it "requires a body of at least 6 characters" do
      pr = build(:prayer_request, body: "hey")
      expect(pr).not_to be_valid
      expect(pr.errors[:body]).to be_present
    end

    it "rejects a body longer than 2000 characters" do
      pr = build(:prayer_request, body: "a" * 2001)
      expect(pr).not_to be_valid
      expect(pr.errors[:body]).to be_present
    end

    it "allows a blank email" do
      pr = build(:prayer_request, email: nil)
      expect(pr).to be_valid
    end

    it "rejects a malformed email when present" do
      pr = build(:prayer_request, email: "not-an-email")
      expect(pr).not_to be_valid
      expect(pr.errors[:email]).to be_present
    end

    it "allows a well-formed email when present" do
      pr = build(:prayer_request, email: "ada@example.com")
      expect(pr).to be_valid
    end
  end

  describe "email normalization" do
    it "strips whitespace and lowercases" do
      pr = PrayerRequest.new(email: "  Mixed.Case@Example.COM ")
      expect(pr.email).to eq("mixed.case@example.com")
    end

    it "stores blank email as nil" do
      pr = PrayerRequest.new(email: "   ")
      expect(pr.email).to be_nil
    end
  end

  describe "status enum" do
    it "defaults to new" do
      expect(PrayerRequest.new.status).to eq("new")
    end

    it "defines the prefixed instance predicates" do
      pr = build(:prayer_request, status: "praying")
      expect(pr.status_praying?).to be true
      expect(pr.status_new?).to be false
    end

    it "is invalid with an unknown status value (validated enum)" do
      pr = build(:prayer_request)
      pr[:status] = "spam"
      expect(pr).not_to be_valid
      expect(pr.errors[:status]).to be_present
    end
  end

  describe "#display_name" do
    it "returns the name when provided and not anonymous" do
      pr = build(:prayer_request, name: "Daniel R.", is_anonymous: false)
      expect(pr.display_name).to eq("Daniel R.")
    end

    it "returns 'Anonymous' when is_anonymous is true even with a name" do
      pr = build(:prayer_request, name: "Daniel R.", is_anonymous: true)
      expect(pr.display_name).to eq("Anonymous")
    end

    it "returns 'Anonymous' when name is blank" do
      pr = build(:prayer_request, name: nil, is_anonymous: false)
      expect(pr.display_name).to eq("Anonymous")
    end

    it "returns 'Anonymous' for the :anonymous trait" do
      pr = build(:prayer_request, :anonymous)
      expect(pr.display_name).to eq("Anonymous")
    end
  end

  describe "#increment_prayed!" do
    it "increments prayed_count by one" do
      pr = create(:prayer_request, :public_praying, prayed_count: 5)
      expect { pr.increment_prayed! }.to change { pr.reload.prayed_count }.from(5).to(6)
    end

    it "is atomic — concurrent increments do not lose updates" do
      pr = create(:prayer_request, :public_praying, prayed_count: 0)
      threads = 5.times.map do
        Thread.new { ActiveRecord::Base.connection_pool.with_connection { PrayerRequest.find(pr.id).increment_prayed! } }
      end
      threads.each(&:join)
      expect(pr.reload.prayed_count).to eq(5)
    end

    it "returns the reloaded record" do
      pr = create(:prayer_request, :public_praying, prayed_count: 0)
      result = pr.increment_prayed!
      expect(result.prayed_count).to eq(1)
    end
  end

  describe "scopes" do
    let!(:new_request)       { create(:prayer_request, status: "new",      is_public: false) }
    let!(:approved_internal) { create(:prayer_request, status: "praying",  is_public: false) }
    let!(:public_praying)    { create(:prayer_request, :public_praying) }
    let!(:public_answered)   { create(:prayer_request, :answered) }
    let!(:archived)          { create(:prayer_request, status: "archived", is_public: true) }

    describe ".visible" do
      it "includes only public praying + answered requests" do
        expect(PrayerRequest.visible).to contain_exactly(public_praying, public_answered)
      end

      it "orders newest first" do
        expect(PrayerRequest.visible.first.created_at).to be >= PrayerRequest.visible.last.created_at
      end
    end

    describe ".answered_only" do
      it "returns only answered + public requests" do
        expect(PrayerRequest.answered_only).to contain_exactly(public_answered)
      end
    end

    describe ".pending_moderation" do
      it "returns only requests with status 'new'" do
        expect(PrayerRequest.pending_moderation).to contain_exactly(new_request)
      end
    end
  end

  describe "#to_s" do
    it "truncates the body to 80 characters" do
      pr = build(:prayer_request, body: "a" * 200)
      expect(pr.to_s.length).to be <= 80
    end
  end
end
