require "rails_helper"

RSpec.describe WelcomeEmailJob, type: :job do
  describe "#perform" do
    it "delivers the welcome email to an active subscriber" do
      subscriber = create(:email_subscriber, email: "welcome@example.com")

      expect {
        described_class.new.perform(subscriber.id)
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "welcome@example.com" ])
      expect(mail.subject).to eq("Welcome to IMPACT Ministry")
    end

    it "skips delivery for an unsubscribed subscriber" do
      subscriber = create(:email_subscriber, :unsubscribed)

      expect {
        described_class.new.perform(subscriber.id)
      }.not_to change { ActionMailer::Base.deliveries.size }
    end

    it "discards silently when the subscriber no longer exists" do
      expect {
        perform_enqueued_jobs { described_class.perform_later(0) }
      }.not_to raise_error
    end

    it "enqueues onto the :mailers queue" do
      expect {
        described_class.perform_later(1)
      }.to have_enqueued_job(described_class).on_queue("mailers")
    end
  end
end
