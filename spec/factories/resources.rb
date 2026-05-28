FactoryBot.define do
  factory :resource do
    sequence(:title) { |n| "#{Faker::Lorem.sentence(word_count: 4).chomp('.').titleize} ##{n}" }
    description {
      [
        Faker::Lorem.paragraph(sentence_count: 4),
        Faker::Lorem.paragraph(sentence_count: 4)
      ].join("\n\n")
    }
    # Cycle through the category enum so factories spread across types.
    sequence(:category) { |n| Resource::CATEGORIES[n % Resource::CATEGORIES.length] }
    requires_email { true }
    featured       { false }

    trait :published do
      published_at { Time.current }
    end

    trait :featured do
      featured { true }
    end

    trait :no_email_gate do
      requires_email { false }
    end

    trait :with_file do
      after(:build) do |resource|
        resource.file.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/sample_resource.pdf")),
          filename: "sample_resource.pdf",
          content_type: "application/pdf"
        )
      end
    end
  end
end
