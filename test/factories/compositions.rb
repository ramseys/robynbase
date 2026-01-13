FactoryBot.define do
  factory :composition do
    Title { Faker::Music.album }
    Artist { "Robyn Hitchcock" }
    Year { Faker::Number.between(from: 1976, to: Date.today.year) }
    Type { ["Album", "EP", "Single", "Compilation"].sample }
    Label { Faker::Company.name + " Records" }

    trait :album do
      Type { "Album" }
    end

    trait :ep do
      Type { "EP" }
    end

    trait :single do
      Type { "Single" }
      Single { true }
    end

    trait :compilation do
      Type { "Compilation" }
    end

    trait :other_band do
      Artist { Faker::Music.band }
    end

    trait :with_tracks do
      transient do
        tracks_count { 12 }
      end

      after(:create) do |composition, evaluator|
        evaluator.tracks_count.times do |i|
          create(:track, composition: composition, Seq: i + 1)
        end
      end
    end

    trait :with_cover_image do
      CoverImage { "album_cover_#{Faker::Alphanumeric.alpha(number: 8)}.jpg" }
    end

    trait :with_comments do
      Comments { Faker::Lorem.paragraph }
    end
  end
end
