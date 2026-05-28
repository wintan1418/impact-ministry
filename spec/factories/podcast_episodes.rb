FactoryBot.define do
  factory :podcast_episode do
    sequence(:title) { |n| "#{Faker::Lorem.sentence(word_count: 4).chomp('.').titleize} ##{n}" }
    description      { Faker::Lorem.paragraph(sentence_count: 4) }
    season           { 1 }
    sequence(:episode_number) { |n| n }
    scheduled_for    { 1.week.ago.to_date }
    audio_url        { "https://cdn.example.com/audio/episode.mp3" }
    duration_seconds { 1_845 } # 00:30:45

    trait :published do
      published_at { 1.day.ago }
    end

    trait :scheduled do
      published_at  { nil }
      scheduled_for { 1.week.from_now.to_date }
    end

    trait :with_guests do
      guest_names { [ "Mara Jenkins", "Theo Banks" ] }
    end

    trait :with_cover do
      cover_photo_slug { "microphone" }
    end
  end
end
