FactoryBot.define do
  factory :donor do
    sequence(:email) { |n| "donor#{n}@example.com" }
    name             { Faker::Name.name }
    address          { {} }
    stripe_customer_id { nil }

    trait :with_stripe do
      sequence(:stripe_customer_id) { |n| "cus_test_#{n}#{SecureRandom.hex(4)}" }
    end

    trait :for_user do
      after(:build) do |donor, _evaluator|
        donor.user ||= create(:user, email_address: donor.email)
      end
    end
  end
end
