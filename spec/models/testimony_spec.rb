require "rails_helper"

RSpec.describe Testimony, type: :model do
  describe "validations" do
    subject { build(:testimony) }

    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_least(20).is_at_most(4000) }
    it { is_expected.to validate_length_of(:name).is_at_most(80) }
    it { is_expected.to validate_length_of(:location).is_at_most(100) }

    it "allows a blank name (anonymous submission)" do
      expect(build(:testimony, :anonymous)).to be_valid
    end

    it "allows a blank location" do
      expect(build(:testimony, location: nil)).to be_valid
    end

    it "rejects a too-short body" do
      t = build(:testimony, body: "too short")
      expect(t).not_to be_valid
      expect(t.errors[:body]).to be_present
    end
  end

  describe "#display_name" do
    it "returns the name when present" do
      expect(build(:testimony, name: "Marcus L.").display_name).to eq("Marcus L.")
    end

    it "falls back to 'A friend' when name is blank" do
      expect(build(:testimony, :anonymous).display_name).to eq("A friend")
    end
  end

  describe "#pull_quote" do
    it "returns the first sentence when one exists" do
      t = build(:testimony, body: "The morning email found me. I had been waiting without knowing it.")
      expect(t.pull_quote).to eq("The morning email found me.")
    end

    it "truncates at ~140 chars when there is no sentence break" do
      long = "a" * 200
      t = build(:testimony, body: long)
      expect(t.pull_quote.length).to be <= 140
      expect(t.pull_quote).to end_with("…")
    end

    it "returns empty string when body is blank" do
      t = Testimony.new
      expect(t.pull_quote).to eq("")
    end
  end

  describe "scopes" do
    it ".approved returns only approved rows" do
      approved = create(:testimony, :approved)
      _pending = create(:testimony)
      expect(Testimony.approved).to contain_exactly(approved)
    end

    it ".featured returns only featured rows" do
      featured = create(:testimony, :featured)
      _approved_only = create(:testimony, :approved)
      expect(Testimony.featured).to contain_exactly(featured)
    end

    it ".recent_first orders by submitted_at desc" do
      old = create(:testimony, :approved, submitted_at: 5.days.ago)
      new_one = create(:testimony, :approved, submitted_at: 1.hour.ago)
      expect(Testimony.recent_first.to_a).to eq([ new_one, old ])
    end

    it ".submitted_first is the same ordering as .recent_first" do
      old = create(:testimony, :approved, submitted_at: 5.days.ago)
      new_one = create(:testimony, :approved, submitted_at: 1.hour.ago)
      expect(Testimony.submitted_first.to_a).to eq([ new_one, old ])
    end
  end

  describe "submitted_at stamping" do
    it "stamps submitted_at on create when blank" do
      freeze_time do
        t = create(:testimony, submitted_at: nil)
        expect(t.submitted_at).to eq(Time.current)
      end
    end

    it "preserves an explicitly-set submitted_at" do
      explicit = 3.days.ago.change(usec: 0)
      t = create(:testimony, submitted_at: explicit)
      expect(t.submitted_at).to be_within(1.second).of(explicit)
    end
  end

  describe "approved_at stamping" do
    it "stamps approved_at when approved flips to true" do
      t = create(:testimony)
      expect(t.approved_at).to be_nil

      freeze_time do
        t.update!(approved: true)
        expect(t.reload.approved_at).to eq(Time.current)
      end
    end

    it "clears approved_at when approved flips back to false" do
      t = create(:testimony, :approved)
      expect(t.approved_at).to be_present

      t.update!(approved: false)
      expect(t.reload.approved_at).to be_nil
    end

    it "does not change approved_at when other fields update" do
      t = create(:testimony, :approved)
      original_approved_at = t.approved_at

      t.update!(body: "An updated body that is plenty long for validation.")
      expect(t.reload.approved_at).to be_within(1.second).of(original_approved_at)
    end
  end

  describe "photo attachment" do
    it "accepts an attached photo via ActiveStorage" do
      t = create(:testimony)
      file = StringIO.new("not-a-real-jpg-but-fine-for-attachment")
      t.photo.attach(io: file, filename: "story.jpg", content_type: "image/jpeg")
      expect(t.photo).to be_attached
      expect(t.photo.filename.to_s).to eq("story.jpg")
    end
  end

  describe "#to_s" do
    it "returns the pull quote" do
      t = build(:testimony, body: "He met me where I was. I'll never get over that.")
      expect(t.to_s).to eq("He met me where I was.")
    end
  end
end
