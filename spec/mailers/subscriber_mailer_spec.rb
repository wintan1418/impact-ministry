require "rails_helper"

RSpec.describe SubscriberMailer, type: :mailer do
  describe "#welcome" do
    let(:subscriber) { create(:email_subscriber, email: "ada@example.com", name: "Ada") }
    let(:mail)       { described_class.with(subscriber: subscriber).welcome }

    it "is addressed to the subscriber" do
      expect(mail.to).to eq([ "ada@example.com" ])
    end

    it "uses a warm, specific subject line" do
      expect(mail.subject).to eq("Welcome to IMPACT Ministry")
    end

    it "is sent from the configured ministry address" do
      expected_from = ENV.fetch("EMAIL_FROM_ADDRESS", "team@impactministry.org")
      expect(mail.from).to eq([ expected_from ])
    end

    it "uses the transactional Postmark message stream" do
      stream = mail.header["message_stream"]&.value || mail["message_stream"]&.value
      expect(stream).to eq("outbound")
    end

    it "renders both HTML and text parts" do
      expect(mail.html_part).to be_present
      expect(mail.text_part).to be_present
    end

    it "includes the unsubscribe link with the subscriber's token" do
      body = mail.html_part.body.to_s
      expect(body).to include(subscriber.token)
      expect(body).to match(%r{/unsubscribe/#{subscriber.token}})
    end

    it "links to today's devotional" do
      body = mail.html_part.body.to_s
      expect(body).to match(/devotionals\/today|Read today's devotional/i)
    end
  end
end
