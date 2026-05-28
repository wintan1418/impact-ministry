FactoryBot.define do
  factory :event do
    sequence(:title) { |n| "#{Faker::Lorem.sentence(word_count: 3).chomp('.').titleize} ##{n}" }
    description      { Faker::Lorem.paragraph(sentence_count: 4) }
    starts_at        { 1.week.from_now }
    location         { "Jackson, MS" }
    published        { true }

    trait :unpublished do
      published { false }
    end

    trait :upcoming do
      starts_at { 1.week.from_now }
    end

    trait :past do
      starts_at { 2.weeks.ago }
      ends_at   { 2.weeks.ago + 2.hours }
    end

    trait :virtual do
      virtual_link { "https://zoom.us/abc" }
      location     { nil }
    end

    trait :capped do
      capacity { 30 }
    end
  end
end
