require "rails_helper"

RSpec.describe VolunteerNotificationJob, type: :job do
  let(:volunteer) { create(:volunteer) }

  around do |ex|
    original = ENV["ADMIN_NOTIFICATION_EMAIL"]
    ENV["ADMIN_NOTIFICATION_EMAIL"] = "team@impactministry.org"
    ex.run
    ENV["ADMIN_NOTIFICATION_EMAIL"] = original
  end

  it "delivers the admin alert" do
    expect {
      described_class.perform_now(volunteer.id)
    }.to change { ActionMailer::Base.deliveries.size }.by(1)

    sent = ActionMailer::Base.deliveries.last
    expect(sent.subject).to include("volunteer")
  end

  it "no-ops when ADMIN_NOTIFICATION_EMAIL is unset" do
    ENV["ADMIN_NOTIFICATION_EMAIL"] = nil
    expect {
      described_class.perform_now(volunteer.id)
    }.not_to change { ActionMailer::Base.deliveries.size }
  end

  it "discards missing volunteers" do
    expect {
      described_class.perform_now(999_999)
    }.not_to raise_error
  end
end
