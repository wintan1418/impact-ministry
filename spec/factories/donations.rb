FactoryBot.define do
  factory :donation do
    donor
    amount_cents { 5_000 }
    currency     { "usd" }
    frequency    { "once" }
    designation  { "general" }
    status       { "succeeded" }
    donated_at   { Time.current }
    sequence(:stripe_payment_intent_id) { |n| "pi_test_#{n}#{SecureRandom.hex(4)}" }
    sequence(:stripe_checkout_session_id) { |n| "cs_test_#{n}#{SecureRandom.hex(4)}" }

    trait :monthly do
      frequency { "monthly" }
      sequence(:stripe_subscription_id) { |n| "sub_test_#{n}#{SecureRandom.hex(4)}" }
    end

    trait :pending do
      status { "pending" }
      donated_at { nil }
    end

    trait :failed do
      status { "failed" }
    end
  end
end
