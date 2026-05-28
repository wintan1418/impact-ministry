FactoryBot.define do
  factory :event_rsvp do
    association :event
    name  { Faker::Name.name }
    sequence(:email) { |n| "rsvp#{n}@impactministry.test" }
    party_size { 1 }
  end
end
