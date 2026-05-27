FactoryBot.define do
  factory :devotional do
    sequence(:title) { |n| "#{Faker::Lorem.sentence(word_count: 3).chomp('.').titleize} ##{n}" }
    scripture_reference { %w[Habakkuk\ 2:1–4 Psalm\ 23 Romans\ 8:28 John\ 1:1–5 Isaiah\ 40:31].sample }
    excerpt { Faker::Lorem.paragraph(sentence_count: 2) }
    sequence(:scheduled_for) { |n| Date.current + n.days }
    tags { [] }
    association :author, factory: :user

    trait :published do
      published_at { Time.current }
    end

    trait :with_body do
      after(:build) do |devotional|
        devotional.body = "<p>The prophet Habakkuk was not given an answer right away. He was given a posture.</p><p>Stand. Watch. Write it down. Wait.</p>"
      end
    end

    trait :for_today do
      scheduled_for { Date.current }
    end
  end
end
