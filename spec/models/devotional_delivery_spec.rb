require "rails_helper"

RSpec.describe DevotionalDelivery, type: :model do
  describe "associations + validations" do
    it "is valid with the factory defaults" do
      expect(build(:devotional_delivery)).to be_valid
    end

    it "requires a devotional" do
      d = build(:devotional_delivery, devotional: nil)
      expect(d).not_to be_valid
      expect(d.errors[:devotional]).to be_present
    end

    it "requires an email_subscriber" do
      d = build(:devotional_delivery, email_subscriber: nil)
      expect(d).not_to be_valid
      expect(d.errors[:email_subscriber]).to be_present
    end

    it "enforces uniqueness of (devotional, email_subscriber)" do
      devotional = create(:devotional)
      subscriber = create(:email_subscriber)
      create(:devotional_delivery, devotional: devotional, email_subscriber: subscriber)
      duplicate = build(:devotional_delivery, devotional: devotional, email_subscriber: subscriber)
      expect(duplicate).not_to be_valid
    end
  end

  describe "scopes" do
    it ".opened returns only deliveries with opened_at" do
      opened = create(:devotional_delivery, :opened)
      _unopened = create(:devotional_delivery)
      expect(described_class.opened).to contain_exactly(opened)
    end

    it ".clicked returns only deliveries with clicked_at" do
      clicked = create(:devotional_delivery, :clicked)
      _opened = create(:devotional_delivery, :opened)
      expect(described_class.clicked).to contain_exactly(clicked)
    end
  end

  describe "#open!" do
    it "sets opened_at to the given time" do
      delivery = create(:devotional_delivery)
      at = 1.minute.ago
      delivery.open!(at: at)
      expect(delivery.reload.opened_at).to be_within(1.second).of(at)
    end

    it "is a no-op once already opened" do
      delivery = create(:devotional_delivery, :opened)
      first = delivery.opened_at
      delivery.open!(at: Time.current)
      expect(delivery.reload.opened_at).to be_within(1.second).of(first)
    end
  end

  describe "#click!" do
    it "sets clicked_at" do
      delivery = create(:devotional_delivery)
      at = 1.minute.ago
      delivery.click!(at: at)
      expect(delivery.reload.clicked_at).to be_within(1.second).of(at)
    end

    it "backfills opened_at if it was nil" do
      delivery = create(:devotional_delivery)
      at = 1.minute.ago
      delivery.click!(at: at)
      expect(delivery.reload.opened_at).to be_within(1.second).of(at)
    end

    it "preserves existing opened_at when clicked" do
      delivery = create(:devotional_delivery, :opened)
      original_open = delivery.opened_at
      delivery.click!(at: Time.current)
      expect(delivery.reload.opened_at).to be_within(1.second).of(original_open)
    end
  end
end
