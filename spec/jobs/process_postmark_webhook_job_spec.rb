require "rails_helper"

RSpec.describe ProcessPostmarkWebhookJob, type: :job do
  describe "#perform" do
    let(:delivery) do
      create(:devotional_delivery, :with_postmark_id, postmark_message_id: "pm-abc-123")
    end

    it "marks the delivery as opened on RecordType=Open" do
      payload = {
        "RecordType" => "Open",
        "MessageID"  => "pm-abc-123",
        "ReceivedAt" => "2026-05-27T12:34:56Z"
      }

      expect {
        described_class.new.perform(payload: payload)
      }.to change { delivery.reload.opened_at }.from(nil).to(be_present)
    end

    it "marks the delivery as clicked on RecordType=Click and backfills opened_at" do
      payload = {
        "RecordType" => "Click",
        "MessageID"  => "pm-abc-123",
        "ReceivedAt" => "2026-05-27T12:34:56Z"
      }

      expect {
        described_class.new.perform(payload: payload)
      }.to change { delivery.reload.clicked_at }.from(nil).to(be_present)

      expect(delivery.reload.opened_at).to be_present
    end

    it "unsubscribes the recipient on RecordType=Bounce" do
      subscriber = create(:email_subscriber, email: "bouncy@example.com")
      payload = {
        "RecordType" => "Bounce",
        "Type"       => "HardBounce",
        "Email"      => "bouncy@example.com"
      }

      expect {
        described_class.new.perform(payload: payload)
      }.to change { subscriber.reload.unsubscribed_at }.from(nil)

      expect(subscriber.active?).to be(false)
    end

    it "unsubscribes the recipient on RecordType=SpamComplaint" do
      subscriber = create(:email_subscriber, email: "angry@example.com")
      payload = {
        "RecordType" => "SpamComplaint",
        "Email"      => "angry@example.com"
      }

      described_class.new.perform(payload: payload)

      expect(subscriber.reload.active?).to be(false)
    end

    it "ignores Open events for unknown MessageIDs without raising" do
      payload = {
        "RecordType" => "Open",
        "MessageID"  => "pm-not-a-real-id",
        "ReceivedAt" => "2026-05-27T12:34:56Z"
      }

      expect {
        described_class.new.perform(payload: payload)
      }.not_to raise_error
    end

    it "ignores Delivery events (we already know we sent it)" do
      payload = {
        "RecordType" => "Delivery",
        "MessageID"  => "pm-abc-123"
      }

      expect {
        described_class.new.perform(payload: payload)
      }.not_to change { delivery.reload.attributes }
    end

    it "logs and ignores unknown RecordTypes" do
      payload = { "RecordType" => "SomethingNew" }

      expect(Rails.logger).to receive(:info).with(/Ignoring RecordType/)

      expect {
        described_class.new.perform(payload: payload)
      }.not_to raise_error
    end
  end
end
