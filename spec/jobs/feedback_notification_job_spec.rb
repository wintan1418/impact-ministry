require "rails_helper"

RSpec.describe FeedbackNotificationJob, type: :job do
  describe "#perform" do
    around do |example|
      old = ENV["ADMIN_NOTIFICATION_EMAIL"]
      ENV["ADMIN_NOTIFICATION_EMAIL"] = "alerts@impactministry.test"
      example.run
    ensure
      ENV["ADMIN_NOTIFICATION_EMAIL"] = old
    end

    it "delivers the alert email for the given FeedbackMessage" do
      message = create(:feedback_message,
                       name: "Lena W.",
                       email: "lena@example.com",
                       kind: "prayer")

      expect {
        described_class.new.perform(message.id)
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "alerts@impactministry.test" ])
      expect(mail.subject).to eq("New contact: prayer — Lena W.")
    end

    it "enqueues onto the :mailers queue" do
      expect {
        described_class.perform_later(1)
      }.to have_enqueued_job(described_class).on_queue("mailers")
    end

    it "discards silently when the FeedbackMessage no longer exists" do
      expect {
        perform_enqueued_jobs { described_class.perform_later(0) }
      }.not_to raise_error
    end
  end
end
