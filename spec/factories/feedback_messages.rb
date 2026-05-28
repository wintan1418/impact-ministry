FactoryBot.define do
  factory :feedback_message do
    sequence(:email) { |n| "writer#{n}@example.com" }
    name    { Faker::Name.name }
    subject { "A note" }
    body    { Faker::Lorem.sentences(number: 3).join(" ") }
    kind    { "general" }

    trait :prayer do
      kind    { "prayer" }
      subject { "A prayer request" }
    end

    trait :partnership do
      kind    { "partnership" }
      subject { "Partnership inquiry" }
    end

    trait :press do
      kind    { "press" }
      subject { "Press inquiry" }
    end

    trait :bug do
      kind    { "bug" }
      subject { "Something broke on the site" }
    end

    trait :replied do
      replied    { true }
      replied_at { 1.day.ago }
    end
  end
end
