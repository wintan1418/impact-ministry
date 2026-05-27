require "rails_helper"

RSpec.describe EmailSubscriber, type: :model do
  describe "validations" do
    subject { build(:email_subscriber) }

    it { is_expected.to validate_presence_of(:email) }

    it "validates case-insensitive uniqueness of email" do
      create(:email_subscriber, email: "dup@example.com")
      dup = build(:email_subscriber, email: "DUP@example.com")
      expect(dup).not_to be_valid
      expect(dup.errors[:email]).to be_present
    end

    it { is_expected.to allow_value("ada@example.com").for(:email) }
    it { is_expected.not_to allow_value("not-an-email").for(:email) }
  end

  describe "source enum" do
    it { is_expected.to define_enum_for(:source).with_values(EmailSubscriber::SOURCES.zip(EmailSubscriber::SOURCES).to_h).backed_by_column_of_type(:string) }

    it "defaults to manual" do
      expect(EmailSubscriber.new.source).to eq("manual")
    end

    it "rejects an invalid source value" do
      sub = build(:email_subscriber)
      sub.source = "billboard"
      expect(sub).not_to be_valid
      expect(sub.errors[:source]).to be_present
    end
  end

  describe "email normalization" do
    it "strips whitespace and lowercases" do
      sub = EmailSubscriber.new(email: "  Mixed.Case@Example.COM ")
      expect(sub.email).to eq("mixed.case@example.com")
    end

    it "persists the normalized value" do
      sub = create(:email_subscriber, email: "  PERSIST@Example.COM ")
      expect(sub.reload.email).to eq("persist@example.com")
    end
  end

  describe "token auto-generation" do
    it "generates a token before validation when blank" do
      sub = build(:email_subscriber, token: nil)
      sub.valid?
      expect(sub.token).to be_present
    end

    it "preserves an explicitly-set token" do
      sub = build(:email_subscriber, token: "custom-token-value")
      sub.valid?
      expect(sub.token).to eq("custom-token-value")
    end

    it "produces unique tokens across rows" do
      a = create(:email_subscriber)
      b = create(:email_subscriber)
      expect(a.token).not_to eq(b.token)
    end
  end

  describe "subscribed_at" do
    it "is stamped on create when blank" do
      freeze_time do
        sub = create(:email_subscriber, subscribed_at: nil)
        expect(sub.subscribed_at).to eq(Time.current)
      end
    end

    it "respects an explicitly-set subscribed_at" do
      explicit = 3.days.ago.change(usec: 0)
      sub = create(:email_subscriber, subscribed_at: explicit)
      expect(sub.subscribed_at).to be_within(1.second).of(explicit)
    end
  end

  describe "#active?" do
    it "is true when unsubscribed_at is nil" do
      expect(build(:email_subscriber).active?).to be true
    end

    it "is false when unsubscribed_at is set" do
      expect(build(:email_subscriber, :unsubscribed).active?).to be false
    end
  end

  describe "#resubscribe!" do
    it "clears unsubscribed_at and refreshes subscribed_at" do
      sub = create(:email_subscriber, :unsubscribed)
      freeze_time do
        sub.resubscribe!
        expect(sub.unsubscribed_at).to be_nil
        expect(sub.subscribed_at).to eq(Time.current)
      end
    end

    it "is idempotent on an already-active subscriber" do
      sub = create(:email_subscriber)
      expect { sub.resubscribe! }.not_to raise_error
      expect(sub.reload.active?).to be true
    end
  end

  describe "#unsubscribe!" do
    it "sets unsubscribed_at" do
      sub = create(:email_subscriber)
      freeze_time do
        sub.unsubscribe!
        expect(sub.unsubscribed_at).to eq(Time.current)
      end
    end
  end

  describe "scopes" do
    it ".active returns only un-unsubscribed rows" do
      active = create(:email_subscriber)
      _unsub = create(:email_subscriber, :unsubscribed)
      expect(EmailSubscriber.active).to contain_exactly(active)
    end

    it ".unsubscribed returns only unsubscribed rows" do
      _active = create(:email_subscriber)
      unsub = create(:email_subscriber, :unsubscribed)
      expect(EmailSubscriber.unsubscribed).to contain_exactly(unsub)
    end
  end

  describe "#to_s" do
    it "returns name when present" do
      expect(build(:email_subscriber, name: "Ada", email: "ada@example.com").to_s).to eq("Ada")
    end

    it "falls back to email when name is blank" do
      expect(build(:email_subscriber, name: nil, email: "nope@example.com").to_s).to eq("nope@example.com")
    end
  end
end
