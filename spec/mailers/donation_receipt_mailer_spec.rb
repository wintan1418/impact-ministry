require "rails_helper"

RSpec.describe DonationReceiptMailer, type: :mailer do
  it "renders the donor's name, amount and designation label" do
    donor = create(:donor, name: "Mary R", email: "mary@example.com")
    donation = create(:donation, donor: donor, amount_cents: 10_000, designation: "youth")

    mail = described_class.with(donation: donation).receipt
    expect(mail.to).to eq([ "mary@example.com" ])
    expect(mail.subject).to include("Thank you")
    html_body = mail.html_part&.body&.to_s.to_s
    text_body = mail.text_part&.body&.to_s.to_s
    combined = html_body + text_body
    expect(combined).to include("Mary R")
    expect(combined).to include("$100")
    expect(combined).to include("Youth")
  end

  it "uses the transactional Postmark stream" do
    donation = create(:donation)
    mail = described_class.with(donation: donation).receipt
    expect(mail["X-PM-Message-Stream"]&.value || mail.message_stream).to be_present
  end
end
