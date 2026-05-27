require "rails_helper"

RSpec.describe DevotionalMailer, type: :mailer do
  describe "#daily" do
    let(:devotional) do
      create(:devotional, :for_today, :with_body,
             title: "When the Vision Tarries",
             scripture_reference: "Habakkuk 2:1–4")
    end
    let(:subscriber) { create(:email_subscriber, email: "reader@example.com") }
    let(:mail) { described_class.with(devotional: devotional, subscriber: subscriber).daily }

    it "is addressed to the subscriber with the correct subject" do
      expect(mail.to).to eq([ "reader@example.com" ])
      expect(mail.subject).to eq("When the Vision Tarries — IMPACT Ministry")
    end

    it "uses the broadcast Postmark message stream" do
      stream = mail.header["message_stream"]&.value || mail["message_stream"]&.value
      expect(stream).to eq("broadcast")
    end

    it "renders title, scripture reference, unsubscribe link, and CTA" do
      html = mail.html_part.body.to_s
      text = mail.text_part.body.to_s

      expect(html).to include("When the Vision Tarries")
      expect(html).to include("Habakkuk 2:1–4")
      expect(html).to include("Read the full devotional")
      expect(html).to match(%r{/unsubscribe/#{subscriber.token}})

      expect(text).to include("When the Vision Tarries")
      expect(text).to include("Habakkuk 2:1–4")
      expect(text).to include(subscriber.token)
    end
  end
end
