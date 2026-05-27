require "rails_helper"

RSpec.describe FailedDispatchAlertJob, type: :job do
  describe "#perform" do
    around do |example|
      ClimateControl.modify(ADMIN_NOTIFICATION_EMAIL: "alerts@impactministry.test") { example.run }
    rescue NameError
      # ClimateControl not bundled — fall through to env-swap fallback.
      old = ENV["ADMIN_NOTIFICATION_EMAIL"]
      ENV["ADMIN_NOTIFICATION_EMAIL"] = "alerts@impactministry.test"
      begin
        example.run
      ensure
        ENV["ADMIN_NOTIFICATION_EMAIL"] = old
      end
    end

    it "sends an alert email when no devotional is published for today" do
      _scheduled = create(:devotional, scheduled_for: Date.current) # not published

      expect {
        described_class.new.perform
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "alerts@impactministry.test" ])
      expect(mail.subject).to eq("No devotional published today — IMPACT")
    end

    it "does not send an alert when a devotional has been published for today" do
      create(:devotional, :for_today, :published)

      expect {
        described_class.new.perform
      }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end
end
