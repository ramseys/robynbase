FactoryBot.define do
  factory :venue do
    Name { (Faker::Music::RockBand.name.to_s[0...35] + " " + ["Hall", "Club"].sample)[0...45] }
    City { Faker::Address.city }
    State { Faker::Address.state_abbr }
    Country { ["USA", "UK", "Canada", "Germany", "France"].sample }

    trait :with_location do
      latitude { Faker::Address.latitude }
      longitude { Faker::Address.longitude }
      street_address1 { Faker::Address.street_address }
    end

    trait :with_notes do
      Notes { Faker::Lorem.paragraph }
    end
  end
end
