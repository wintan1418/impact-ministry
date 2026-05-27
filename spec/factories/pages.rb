FactoryBot.define do
  factory :page do
    sequence(:title) { |n| "Page Title #{n}" }
    published { true }
    seo_meta  { { "description" => "A short, true page." } }

    after(:build) do |page|
      page.body = "<p>A short, true word from a quiet morning.</p>" if page.body.blank?
    end

    trait :unpublished do
      published { false }
    end
  end
end
