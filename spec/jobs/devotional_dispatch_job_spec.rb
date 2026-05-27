require "rails_helper"

RSpec.describe DevotionalDispatchJob, type: :job do
  describe "#perform" do
    it "logs a warning and returns when no devotional is scheduled for today" do
      _future = create(:devotional, scheduled_for: Date.current + 3.days)

      expect(Rails.logger).to receive(:warn).with(/No devotional scheduled/)

      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(DevotionalDeliveryJob)
    end

    it "publishes the devotional and enqueues no jobs when there are no active subscribers" do
      devotional = create(:devotional, scheduled_for: Date.current)
      create(:email_subscriber, :unsubscribed) # inactive — should be skipped

      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(DevotionalDeliveryJob)

      expect(devotional.reload).to be_published
    end

    it "publishes the devotional and enqueues one DevotionalDeliveryJob per active subscriber" do
      devotional = create(:devotional, scheduled_for: Date.current)
      subs = Array.new(3) { create(:email_subscriber) }

      expect {
        described_class.new.perform
      }.to have_enqueued_job(DevotionalDeliveryJob).exactly(3).times

      expect(devotional.reload).to be_published

      subs.each do |s|
        expect(DevotionalDeliveryJob).to have_been_enqueued.with(
          devotional_id: devotional.id, subscriber_id: s.id
        )
      end
    end

    it "is idempotent — re-running after a successful pass does not double-enqueue" do
      devotional = create(:devotional, scheduled_for: Date.current)
      sub_a = create(:email_subscriber)
      sub_b = create(:email_subscriber)

      # Simulate the first pass having already created delivery rows.
      create(:devotional_delivery, devotional: devotional, email_subscriber: sub_a)
      create(:devotional_delivery, devotional: devotional, email_subscriber: sub_b)
      devotional.publish!

      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(DevotionalDeliveryJob)
    end
  end

  describe "queue" do
    it "enqueues onto :devotionals" do
      expect {
        described_class.perform_later
      }.to have_enqueued_job(described_class).on_queue("devotionals")
    end
  end
end
