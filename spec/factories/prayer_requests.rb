FactoryBot.define do
  factory :prayer_request do
    name { Faker::Name.first_name }
    email { nil }
    body { Faker::Lorem.sentences(number: 2).join(" ") }
    is_anonymous { false }
    status { "new" }
    is_public { false }
    prayed_count { 0 }

    trait :anonymous do
      is_anonymous { true }
      name { nil }
    end

    trait :public_praying do
      status { "praying" }
      is_public { true }
    end

    trait :answered do
      status { "answered" }
      is_public { true }
    end
  end
end
