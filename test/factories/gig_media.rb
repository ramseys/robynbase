FactoryBot.define do
  factory :gig_medium do
    association :gig, factory: :gig
    title { "#{Faker::Music.band} - Live at #{Faker::Address.city}" }
    mediaid { Faker::Alphanumeric.alphanumeric(number: 10) }
    mediatype { [1, 2, 3, 4, 5, 6].sample }  # YouTube, Archive.org, Vimeo, Soundcloud
    Chrono { Faker::Number.between(from: 1, to: 20) }
    showplaylist { 0 }

    trait :youtube do
      mediatype { 1 }  # YouTube
      mediaid { Faker::Alphanumeric.alphanumeric(number: 11) }  # YouTube video IDs are 11 characters
    end

    trait :archive_org_video do
      mediatype { 2 }
    end

    trait :archive_org_audio do
      mediatype { 4 }
    end

    trait :vimeo do
      mediatype { 5 }
      mediaid { Faker::Number.number(digits: 9).to_s }
    end

    trait :soundcloud do
      mediatype { 6 }
    end

    trait :with_playlist do
      showplaylist { 1 }
    end
  end
end
