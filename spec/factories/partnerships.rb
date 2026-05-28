FactoryBot.define do
  factory :partnership do
    sequence(:organization_name) { |n| "Cedar Grove Church ##{n}" }
    contact_name                 { Faker::Name.name }
    sequence(:contact_email)     { |n| "partner#{n}@example.com" }
    contact_phone                { nil }
    organization_type            { "church" }
    interest_areas               { %w[devotionals] }
    message do
      "We'd love to talk about co-publishing a devotional series for our " \
        "Wednesday night gatherings this fall."
    end
    status { "new" }

    # --- Organization-type traits --------------------------------------
    trait :church do
      organization_type { "church" }
    end

    trait :nonprofit do
      organization_type { "nonprofit" }
      organization_name { "Delta Hope Collective" }
    end

    trait :school do
      organization_type { "school" }
      organization_name { "Greenwood Christian Academy" }
    end

    trait :business do
      organization_type { "business" }
      organization_name { "Threshold Coffee Roasters" }
    end

    trait :other do
      organization_type { "other" }
    end

    # --- Status traits -------------------------------------------------
    trait :new_status do
      status { "new" }
    end

    trait :in_review do
      status { "in_review" }
    end

    trait :engaged do
      status { "engaged" }
    end

    trait :declined do
      status { "declined" }
    end

    trait :archived do
      status { "archived" }
    end

    # --- Convenience ---------------------------------------------------
    trait :with_phone do
      contact_phone { "601-555-0143" }
    end

    trait :multi_interest do
      interest_areas { %w[devotionals podcast grants] }
    end
  end
end
