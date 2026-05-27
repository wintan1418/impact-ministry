require "rails_helper"

RSpec.describe User, type: :model do
  describe "authentication" do
    it { is_expected.to have_secure_password }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
  end

  describe "role enum" do
    it { is_expected.to define_enum_for(:role).with_values(visitor: "visitor", subscriber: "subscriber", editor: "editor", admin: "admin").backed_by_column_of_type(:string) }

    it "defaults to subscriber" do
      expect(User.new.role).to eq("subscriber")
    end

    it "exposes predicate methods for each role" do
      expect(build(:user, role: "visitor")).to be_visitor
      expect(build(:user, role: "subscriber")).to be_subscriber
      expect(build(:user, role: "editor")).to be_editor
      expect(build(:user, role: "admin")).to be_admin
    end
  end

  describe "#staff?" do
    it "is true for editors" do
      expect(build(:user, :editor).staff?).to be true
    end

    it "is true for admins" do
      expect(build(:user, :admin).staff?).to be true
    end

    it "is false for subscribers" do
      expect(build(:user).staff?).to be false
    end

    it "is false for visitors" do
      expect(build(:user, role: "visitor").staff?).to be false
    end
  end

  describe "#confirmed?" do
    it "is true when confirmed_at is set" do
      expect(build(:user, :confirmed).confirmed?).to be true
    end

    it "is false when confirmed_at is nil" do
      expect(build(:user, confirmed_at: nil).confirmed?).to be false
    end
  end

  describe "#to_s" do
    it "returns the name when present" do
      user = build(:user, name: "Ada Lovelace", email_address: "ada@example.com")
      expect(user.to_s).to eq("Ada Lovelace")
    end

    it "falls back to email_address when name is blank" do
      user = build(:user, name: "", email_address: "fallback@example.com")
      expect(user.to_s).to eq("fallback@example.com")
    end

    it "falls back to email_address when name is nil" do
      user = build(:user, name: nil, email_address: "nil-name@example.com")
      expect(user.to_s).to eq("nil-name@example.com")
    end
  end

  describe "email_address normalization" do
    it "strips surrounding whitespace and downcases on assignment" do
      user = User.new(email_address: "  Mixed.Case@Example.COM  ")
      expect(user.email_address).to eq("mixed.case@example.com")
    end

    it "persists the normalized value" do
      user = create(:user, email_address: "  Persisted@Example.COM ")
      expect(user.reload.email_address).to eq("persisted@example.com")
    end
  end
end
