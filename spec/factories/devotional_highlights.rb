FactoryBot.define do
  factory :devotional_highlight do
    user
    devotional
    text_range { { start: 100, end: 180, text: "a short, true word saved at " + Faker::Time.backward(days: 7).iso8601 }.to_json }
    saved_at   { Time.current }
  end
end
