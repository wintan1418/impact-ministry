require "rails_helper"

RSpec.describe SundayRecapDeliveryJob, type: :job do
  let(:week_ending) { Date.current }
  let(:subscriber)  { create(:email_subscriber, email: "reader@example.com") }

  def create_published_devotionals(count, ending_on: week_ending)
    Array.new(count) do |i|
      create(:devotional, :published, :with_body, scheduled_for: ending_on - i.days)
    end
  end

  describe "#perform" do
    it "delivers the recap email via SundayRecapMailer" do
      create_published_devotionals(5)

      expect {
        described_class.new.perform(subscriber_id: subscriber.id, week_ending: week_ending.iso8601)
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "reader@example.com" ])
      expect(mail.subject).to include("IMPACT Ministry recap")
    end

    it "short-circuits for an inactive (unsubscribed) subscriber" do
      create_published_devotionals(5)
      inactive = create(:email_subscriber, :unsubscribed)

      expect {
        described_class.new.perform(subscriber_id: inactive.id, week_ending: week_ending.iso8601)
      }.not_to change { ActionMailer::Base.deliveries.size }
    end

    it "does not send when no devotionals fall in the window" do
      # No published devotionals at all.
      expect {
        described_class.new.perform(subscriber_id: subscriber.id, week_ending: week_ending.iso8601)
      }.not_to change { ActionMailer::Base.deliveries.size }
    end

    it "is configured to discard when the subscriber row is gone" do
      handler = described_class.rescue_handlers.find do |entry|
        Array(entry[0]).include?("ActiveRecord::RecordNotFound")
      end
      expect(handler).to be_present
    end
  end

  describe "queue" do
    it "enqueues onto :mailers" do
      expect {
        described_class.perform_later(subscriber_id: 1, week_ending: week_ending.iso8601)
      }.to have_enqueued_job(described_class).on_queue("mailers")
    end
  end
end
