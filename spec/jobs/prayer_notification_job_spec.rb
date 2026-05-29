require "rails_helper"

RSpec.describe PrayerNotificationJob, type: :job do
  let(:prayer) { create(:prayer_request) }

  around do |ex|
    original = ENV["ADMIN_NOTIFICATION_EMAIL"]
    ENV["ADMIN_NOTIFICATION_EMAIL"] = "team@impactministry.org"
    ex.run
    ENV["ADMIN_NOTIFICATION_EMAIL"] = original
  end

  it "delivers the admin alert" do
    expect {
      described_class.perform_now(prayer.id)
    }.to change { ActionMailer::Base.deliveries.size }.by(1)

    sent = ActionMailer::Base.deliveries.last
    expect(sent.to).to eq([ "team@impactministry.org" ])
    expect(sent.subject).to include("prayer")
  end

  it "no-ops when ADMIN_NOTIFICATION_EMAIL is unset" do
    ENV["ADMIN_NOTIFICATION_EMAIL"] = nil
    expect {
      described_class.perform_now(prayer.id)
    }.not_to change { ActionMailer::Base.deliveries.size }
  end

  it "discards missing prayer requests" do
    expect {
      described_class.perform_now(999_999)
    }.not_to raise_error
  end
end
