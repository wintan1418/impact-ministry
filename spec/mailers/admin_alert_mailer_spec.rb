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

  describe "#new_feedback" do
    around do |example|
      old = ENV["ADMIN_NOTIFICATION_EMAIL"]
      ENV["ADMIN_NOTIFICATION_EMAIL"] = "alerts@impactministry.test"
      example.run
    ensure
      ENV["ADMIN_NOTIFICATION_EMAIL"] = old
    end

    let(:message) do
      create(:feedback_message,
             name: "Marcus L.",
             email: "marcus@example.com",
             subject: "A short note",
             kind: "partnership",
             body: "Our small church would love to talk about partnering on a Lenten series.")
    end

    it "is sent to the configured admin notification address on the transactional stream" do
      mail = described_class.with(feedback_id: message.id).new_feedback

      expect(mail.to).to eq([ "alerts@impactministry.test" ])
      expect(mail.subject).to eq("New contact: partnership — Marcus L.")

      stream = mail.header["message_stream"]&.value || mail["message_stream"]&.value
      expect(stream).to eq("outbound")
    end

    it "includes the body, email, and admin record link in the HTML and text parts" do
      mail = described_class.with(feedback_id: message.id).new_feedback

      html = mail.html_part.body.to_s
      text = mail.text_part.body.to_s

      expect(html).to include("Marcus L.")
      expect(html).to include("marcus@example.com")
      expect(html).to include("Lenten series")
      expect(html).to include("/admin/feedback_messages/#{message.id}")

      expect(text).to include("Marcus L.")
      expect(text).to include("marcus@example.com")
      expect(text).to include("Lenten series")
      expect(text).to include("/admin/feedback_messages/#{message.id}")
    end
  end
end
