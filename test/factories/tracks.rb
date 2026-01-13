FactoryBot.define do
  factory :track do
    association :composition, factory: :composition
    association :song, factory: :song
    Seq { Faker::Number.between(from: 1, to: 15) }
    Disc { 1 }
    Time { "#{Faker::Number.between(from: 2, to: 5)}:#{sprintf('%02d', Faker::Number.between(from: 0, to: 59))}" }

    trait :disc_two do
      Disc { 2 }
    end

    trait :hidden do
      Hidden { true }
    end

    trait :bonus do
      bonus { true }
    end

    trait :with_version_notes do
      VersionNotes { ["live version", "demo", "alternate take", "extended version"].sample }
    end
  end
end
