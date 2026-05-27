FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@impactministry.test" }
    password { "correct horse battery staple" }
    name { Faker::Name.name }
    role { "subscriber" }

    trait :editor do
      role { "editor" }
    end

    trait :admin do
      role { "admin" }
    end

    trait :confirmed do
      confirmed_at { 1.day.ago }
    end
  end
end
