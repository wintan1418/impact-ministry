require "rails_helper"

RSpec.describe DevotionalDeliveryJob, type: :job do
  describe "#perform" do
    let(:devotional) { create(:devotional, :for_today, :with_body) }
    let(:subscriber) { create(:email_subscriber, email: "reader@example.com") }

    it "creates a DevotionalDelivery row and sends the daily email" do
      expect {
        described_class.new.perform(devotional_id: devotional.id, subscriber_id: subscriber.id)
      }.to change { DevotionalDelivery.count }.by(1)
        .and change { ActionMailer::Base.deliveries.size }.by(1)

      delivery = DevotionalDelivery.last
      expect(delivery.devotional).to eq(devotional)
      expect(delivery.email_subscriber).to eq(subscriber)
      expect(delivery.sent_at).to be_within(2.seconds).of(Time.current)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "reader@example.com" ])
      expect(mail.subject).to eq("#{devotional.title} — IMPACT Ministry")
    end

    it "is idempotent — re-running for the same (devotional, subscriber) does not double-send" do
      described_class.new.perform(devotional_id: devotional.id, subscriber_id: subscriber.id)

      expect {
        described_class.new.perform(devotional_id: devotional.id, subscriber_id: subscriber.id)
      }.to change { DevotionalDelivery.count }.by(0)
        .and change { ActionMailer::Base.deliveries.size }.by(0)
    end

    it "skips delivery for an inactive (unsubscribed) subscriber" do
      inactive = create(:email_subscriber, :unsubscribed)

      expect {
        described_class.new.perform(devotional_id: devotional.id, subscriber_id: inactive.id)
      }.to change { DevotionalDelivery.count }.by(0)
        .and change { ActionMailer::Base.deliveries.size }.by(0)
    end
  end

  describe "queue" do
    it "enqueues onto :mailers" do
      expect {
        described_class.perform_later(devotional_id: 1, subscriber_id: 1)
      }.to have_enqueued_job(described_class).on_queue("mailers")
    end
  end
end
