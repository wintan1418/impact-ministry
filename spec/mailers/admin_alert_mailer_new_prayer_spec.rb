require "rails_helper"

RSpec.describe AdminAlertMailer, type: :mailer do
  describe ".new_prayer" do
    let(:prayer) { create(:prayer_request, name: "Mary R", email: "m@example.com", body: "Pray for my mother's surgery on Tuesday.") }

    around do |ex|
      original = ENV["ADMIN_NOTIFICATION_EMAIL"]
      ENV["ADMIN_NOTIFICATION_EMAIL"] = "team@impactministry.org"
      ex.run
      ENV["ADMIN_NOTIFICATION_EMAIL"] = original
    end

    it "renders the body, contact, and admin URL" do
      mail = described_class.with(prayer_request_id: prayer.id).new_prayer
      expect(mail.to).to eq([ "team@impactministry.org" ])
      expect(mail.subject).to include("prayer")

      combined = (mail.html_part&.body.to_s) + (mail.text_part&.body.to_s)
      expect(combined).to include("Mary R")
      expect(combined).to include("Pray for my mother's surgery")
      expect(combined).to include("/admin/prayer_requests/#{prayer.id}")
    end

    it "redacts the name when anonymous" do
      anon = create(:prayer_request, is_anonymous: true, name: "Mary R", body: "private note")
      mail = described_class.with(prayer_request_id: anon.id).new_prayer
      combined = (mail.html_part&.body.to_s) + (mail.text_part&.body.to_s)
      expect(combined).to include("anonymous")
      expect(combined).not_to include("Mary R")
    end
  end
end
