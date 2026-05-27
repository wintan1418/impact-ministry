FactoryBot.define do
  factory :devotional_delivery do
    association :devotional
    association :email_subscriber
    sent_at { Time.current }

    trait :opened do
      opened_at { 1.hour.ago }
    end

    trait :clicked do
      opened_at { 2.hours.ago }
      clicked_at { 1.hour.ago }
    end

    trait :with_postmark_id do
      sequence(:postmark_message_id) { |n| "pm-message-#{n}-#{SecureRandom.hex(4)}" }
    end
  end
end
