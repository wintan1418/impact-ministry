require "rails_helper"

RSpec.describe FeedbackMessage, type: :model do
  describe "validations" do
    subject { build(:feedback_message) }

    it "is valid with factory defaults" do
      expect(subject).to be_valid
    end

    it "requires a name" do
      msg = build(:feedback_message, name: nil)
      expect(msg).not_to be_valid
      expect(msg.errors[:name]).to be_present
    end

    it "rejects a name longer than 120 characters" do
      msg = build(:feedback_message, name: "a" * 121)
      expect(msg).not_to be_valid
      expect(msg.errors[:name]).to be_present
    end

    it "requires an email" do
      msg = build(:feedback_message, email: nil)
      expect(msg).not_to be_valid
      expect(msg.errors[:email]).to be_present
    end

    it "rejects a malformed email" do
      msg = build(:feedback_message, email: "not-an-email")
      expect(msg).not_to be_valid
      expect(msg.errors[:email]).to be_present
    end

    it "rejects an email longer than 160 characters" do
      msg = build(:feedback_message, email: "#{'a' * 160}@example.com")
      expect(msg).not_to be_valid
      expect(msg.errors[:email]).to be_present
    end

    it "requires a body" do
      msg = build(:feedback_message, body: nil)
      expect(msg).not_to be_valid
      expect(msg.errors[:body]).to be_present
    end

    it "requires a body of at least 6 characters" do
      msg = build(:feedback_message, body: "hi")
      expect(msg).not_to be_valid
      expect(msg.errors[:body]).to be_present
    end

    it "rejects a body longer than 6000 characters" do
      msg = build(:feedback_message, body: "a" * 6001)
      expect(msg).not_to be_valid
      expect(msg.errors[:body]).to be_present
    end

    it "permits a blank subject (it's optional)" do
      msg = build(:feedback_message, subject: nil)
      expect(msg).to be_valid
    end
  end

  describe "kind enum" do
    it "defaults to general" do
      expect(FeedbackMessage.new.kind).to eq("general")
    end

    it "accepts all defined kinds" do
      FeedbackMessage::KINDS.each do |kind|
        msg = build(:feedback_message, kind: kind)
        expect(msg).to be_valid, "expected #{kind} to be a valid kind"
      end
    end

    it "is invalid with an unknown kind value (validated enum)" do
      msg = build(:feedback_message)
      msg[:kind] = "spam"
      expect(msg).not_to be_valid
      expect(msg.errors[:kind]).to be_present
    end
  end

  describe "email normalization" do
    it "strips whitespace and lowercases" do
      msg = FeedbackMessage.new(email: "  Mixed.Case@Example.COM ")
      expect(msg.email).to eq("mixed.case@example.com")
    end
  end

  describe "scopes" do
    let!(:unread_general)      { create(:feedback_message, kind: "general") }
    let!(:unread_prayer)       { create(:feedback_message, :prayer) }
    let!(:unread_partnership)  { create(:feedback_message, :partnership) }
    let!(:replied_message)     { create(:feedback_message, :replied) }

    describe ".unread" do
      it "returns only messages where replied is false" do
        expect(FeedbackMessage.unread)
          .to contain_exactly(unread_general, unread_prayer, unread_partnership)
      end
    end

    describe ".recent_first" do
      it "orders newest first" do
        ordered = FeedbackMessage.recent_first.to_a
        expect(ordered.first.created_at).to be >= ordered.last.created_at
      end
    end

    describe ".by_kind" do
      it "filters by the given kind" do
        expect(FeedbackMessage.by_kind("prayer")).to contain_exactly(unread_prayer)
      end
    end
  end

  describe "#mark_replied!" do
    it "sets replied true + replied_at" do
      msg = create(:feedback_message)
      expect(msg.replied).to be false

      msg.mark_replied!
      expect(msg.reload.replied).to be true
      expect(msg.replied_at).to be_within(2.seconds).of(Time.current)
    end

    it "accepts an explicit `at:`" do
      msg = create(:feedback_message)
      ts  = 1.hour.ago
      msg.mark_replied!(at: ts)
      expect(msg.reload.replied_at).to be_within(1.second).of(ts)
    end
  end

  describe "#to_s" do
    it "returns the subject when present" do
      msg = build(:feedback_message, subject: "Quick question")
      expect(msg.to_s).to eq("Quick question")
    end

    it "truncates the body to 60 chars when subject is blank" do
      msg = build(:feedback_message, subject: nil, body: "a" * 200)
      expect(msg.to_s.length).to be <= 60
    end
  end
end
