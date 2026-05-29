FactoryBot.define do
  factory :volunteer do
    name              { Faker::Name.name }
    sequence(:email)  { |n| "volunteer#{n}@example.com" }
    phone             { nil }
    availability      { "flexible" }
    interest_areas    { %w[writing prayer] }
    gifts             { "Decade of editorial work; comfortable with InDesign and tight deadlines." }
    message do
      "I read the newsletter for the better part of a year and would love " \
        "to give a few hours a week to whatever is most useful."
    end
    status { "new" }

    trait :writing do
      interest_areas { %w[writing] }
    end

    trait :events do
      interest_areas { %w[events outreach] }
      availability   { "weekends" }
    end
  end
end
