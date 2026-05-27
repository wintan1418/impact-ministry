FactoryBot.define do
  factory :email_subscriber do
    sequence(:email) { |n| "reader#{n}@impactministry.test" }
    name { Faker::Name.name }
    source { "manual" }

    trait :footer do
      source { "footer" }
    end

    trait :inline do
      source { "inline" }
    end

    trait :unsubscribed do
      unsubscribed_at { 1.day.ago }
    end
  end
end
