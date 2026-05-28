FactoryBot.define do
  factory :testimony do
    name     { Faker::Name.name }
    location { "Jackson, MS" }
    body     { Faker::Lorem.sentences(number: 4).join(" ") }
    approved { false }
    featured { false }

    trait :approved do
      approved    { true }
      approved_at { 1.day.ago }
    end

    trait :featured do
      approved    { true }
      featured    { true }
      approved_at { 1.day.ago }
    end

    trait :anonymous do
      name { nil }
    end
  end
end
