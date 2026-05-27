require "rails_helper"

RSpec.describe AdminAlertMailer, type: :mailer do
  describe "#missing_devotional" do
    around do |example|
      old = ENV["ADMIN_NOTIFICATION_EMAIL"]
      ENV["ADMIN_NOTIFICATION_EMAIL"] = "alerts@impactministry.test"
      example.run
    ensure
      ENV["ADMIN_NOTIFICATION_EMAIL"] = old
    end

    it "is sent to the configured admin notification address on the transactional stream" do
      mail = described_class.with(date: Date.new(2026, 5, 27)).missing_devotional

      expect(mail.to).to eq([ "alerts@impactministry.test" ])
      expect(mail.subject).to eq("No devotional published today — IMPACT")

      stream = mail.header["message_stream"]&.value || mail["message_stream"]&.value
      expect(stream).to eq("outbound")

      html = mail.html_part.body.to_s
      expect(html).to include("Wednesday, May 27, 2026")
    end
  end
end
