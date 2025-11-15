FactoryBot.define do
  factory :gig do
    association :venue, factory: :venue
    GigDate { Faker::Date.between(from: '1976-01-01', to: Date.today) }
    BilledAs { ["Robyn Hitchcock", "Robyn Hitchcock & The Egyptians", "Robyn Hitchcock & The Venus 3", "The Soft Boys"].sample }
    GigYear { GigDate&.year&.to_s }

    trait :with_setlist do
      transient do
        songs_count { 10 }
      end

      after(:create) do |gig, evaluator|
        create_list(:gigset, evaluator.songs_count, gig: gig)
      end
    end

    trait :with_reviews do
      Reviews { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    end

    trait :with_media do
      TapeExists { true }

      after(:create) do |gig|
        create(:gig_medium, gig: gig)
      end
    end

    trait :with_guests do
      Guests { Faker::Music.band }
    end

    trait :circa do
      Circa { true }
    end

    trait :no_date do
      GigDate { nil }
      GigYear { Faker::Number.between(from: 1976, to: Date.today.year).to_s }
    end
  end
end
