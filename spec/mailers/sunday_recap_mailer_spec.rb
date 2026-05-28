require "rails_helper"

RSpec.describe SundayRecapMailer, type: :mailer do
  describe "#recap" do
    let(:week_ending) { Date.new(2026, 5, 24) }
    let(:subscriber)  { create(:email_subscriber, email: "reader@example.com") }
    let(:devotionals) do
      [
        create(:devotional, :published, :with_body,
               title: "Stand. Watch. Wait.",
               scripture_reference: "Habakkuk 2:1–4",
               scheduled_for: week_ending),
        create(:devotional, :published, :with_body,
               title: "Quiet Strength",
               scripture_reference: "Isaiah 30:15",
               scheduled_for: week_ending - 2.days),
        create(:devotional, :published, :with_body,
               title: "A Light, Stepwise",
               scripture_reference: "Psalm 119:105",
               scheduled_for: week_ending - 4.days)
      ]
    end

    let(:mail) do
      described_class.with(
        subscriber: subscriber,
        devotionals: devotionals,
        week_ending: week_ending
      ).recap
    end

    it "is addressed to the subscriber" do
      expect(mail.to).to eq([ "reader@example.com" ])
    end

    it "has a subject containing the brand and the week's ending date" do
      expect(mail.subject).to eq(
        "This week, in a quiet word — IMPACT Ministry recap for May 24"
      )
    end

    it "uses the broadcast Postmark message stream" do
      stream = mail.header["message_stream"]&.value || mail["message_stream"]&.value
      expect(stream).to eq("broadcast")
    end

    it "renders every devotional title in both parts" do
      html = mail.html_part.body.to_s
      text = mail.text_part.body.to_s

      devotionals.each do |d|
        expect(html).to include(d.title)
        expect(text).to include(d.title)
      end
    end

    it "renders the unsubscribe link with the subscriber's token" do
      html = mail.html_part.body.to_s
      text = mail.text_part.body.to_s

      expect(html).to match(%r{/unsubscribe/#{subscriber.token}})
      expect(text).to include(subscriber.token)
    end

    it "renders the recap masthead and the 'reply with feedback' invitation" do
      html = mail.html_part.body.to_s

      expect(html).to include("IMPACT Ministry")
      expect(html).to include("Sunday recap")
      expect(html).to include("Reply with feedback")
    end
  end
end
