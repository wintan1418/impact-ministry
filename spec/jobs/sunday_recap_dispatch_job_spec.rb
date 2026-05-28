require "rails_helper"

RSpec.describe SundayRecapDispatchJob, type: :job do
  let(:week_ending) { Date.current }

  def create_published_devotionals(count, ending_on: week_ending)
    Array.new(count) do |i|
      create(:devotional, :published, scheduled_for: ending_on - i.days)
    end
  end

  describe "#perform" do
    it "enqueues one SundayRecapDeliveryJob per active subscriber when the week has 5 devotionals and 80 subscribers" do
      create_published_devotionals(5)
      subs = Array.new(80) { create(:email_subscriber) }
      create(:email_subscriber, :unsubscribed) # should be skipped

      expect {
        described_class.new.perform(week_ending: week_ending)
      }.to have_enqueued_job(SundayRecapDeliveryJob).exactly(80).times

      subs.first(3).each do |s|
        expect(SundayRecapDeliveryJob).to have_been_enqueued.with(
          subscriber_id: s.id, week_ending: week_ending.iso8601
        )
      end
    end

    it "logs a warning and enqueues nothing when fewer than 3 published devotionals are in the window" do
      create_published_devotionals(2)
      create(:email_subscriber)
      create(:email_subscriber)

      expect(Rails.logger).to receive(:warn).with(/Only 2 published devotional/)

      expect {
        described_class.new.perform(week_ending: week_ending)
      }.not_to have_enqueued_job(SundayRecapDeliveryJob)
    end

    it "enqueues nothing when there are no active subscribers, even with enough devotionals" do
      create_published_devotionals(5)
      create(:email_subscriber, :unsubscribed)

      expect {
        described_class.new.perform(week_ending: week_ending)
      }.not_to have_enqueued_job(SundayRecapDeliveryJob)
    end

    it "ignores devotionals scheduled outside the 7-day window" do
      # Five in-window
      create_published_devotionals(5)
      # Two well outside the window — should not count toward threshold reset.
      create(:devotional, :published, scheduled_for: week_ending - 30.days)
      create(:devotional, :published, scheduled_for: week_ending + 5.days)

      sub = create(:email_subscriber)

      expect {
        described_class.new.perform(week_ending: week_ending)
      }.to have_enqueued_job(SundayRecapDeliveryJob).exactly(1).times.with(
        subscriber_id: sub.id, week_ending: week_ending.iso8601
      )
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
