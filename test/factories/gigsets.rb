FactoryBot.define do
  factory :gigset do
    association :gig, factory: :gig
    association :song, factory: :song
    Chrono { Faker::Number.between(from: 1, to: 20) }

    trait :encore do
      Encore { true }
    end

    trait :soundcheck do
      Soundcheck { true }
    end

    trait :segue do
      Segue { true }
    end

    trait :with_version_notes do
      VersionNotes { ["acoustic", "electric", "solo", "with band"].sample }
    end
  end
end
