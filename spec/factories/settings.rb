FactoryBot.define do
  factory :setting do
    sequence(:key) { |n| "setting_key_#{n}" }
    kind  { "string" }
    value { "a value" }
    description { "Sample setting." }

    trait :boolean do
      kind  { "boolean" }
      value { "true" }
    end

    trait :integer do
      kind  { "integer" }
      value { "42" }
    end

    trait :json do
      kind  { "json" }
      value { '{"answer":42}' }
    end
  end
end
