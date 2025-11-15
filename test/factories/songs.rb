FactoryBot.define do
  factory :song do
    Song { Faker::Music::RockBand.song }
    Author { nil }  # nil means written by Robyn Hitchcock
    Prefix { nil }

    trait :with_prefix do
      Prefix { ["The", "A", "An"].sample }
    end

    trait :cover do
      Author { Faker::Music.band }
      OrigBand { Faker::Music.band }
    end

    trait :with_lyrics do
      Lyrics { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
      show_lyrics { true }
    end

    trait :with_tabs do
      Tab { "G C D Em\n#{Faker::Lorem.paragraph}" }
    end

    trait :improvised do
      Improvised { true }
    end

    trait :with_comments do
      Comments { Faker::Lorem.paragraph }
    end

    trait :with_performances do
      transient do
        performances_count { 3 }
      end

      after(:create) do |song, evaluator|
        create_list(:gigset, evaluator.performances_count, song: song)
      end
    end

    trait :on_album do
      transient do
        albums_count { 1 }
      end

      after(:create) do |song, evaluator|
        create_list(:track, evaluator.albums_count, song: song)
      end
    end
  end
end
