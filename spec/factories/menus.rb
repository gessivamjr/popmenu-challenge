FactoryBot.define do
  factory :menu do
    sequence(:name) { |n| "Menu #{n}" }
    description { "A delicious menu description" }
    category { "breakfast" }
    active { true }
    starts_at { 8 }
    ends_at { 12 }

    trait :inactive do
      active { false }
    end

    trait :lunch do
      category { "lunch" }
      starts_at { 12 }
      ends_at { 17 }
    end

    trait :dinner do
      category { "dinner" }
      starts_at { 17 }
      ends_at { 22 }
    end

    trait :without_times do
      starts_at { nil }
      ends_at { nil }
    end
  end
end
