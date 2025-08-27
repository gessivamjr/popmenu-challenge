FactoryBot.define do
  factory :menu_item do
    sequence(:name) { |n| "Menu Item #{n}" }
    description { "A delicious menu item description" }
    price { 12.99 }
    currency { "USD" }
    category { "appetizer" }
    available { true }
    prep_time_minutes { 15 }
    image_url { "https://example.com/image.jpg" }

    association :menu

    trait :unavailable do
      available { false }
    end

    trait :expensive do
      price { 49.99 }
    end

    trait :main_course do
      category { "main_course" }
      price { 24.99 }
      prep_time_minutes { 25 }
    end

    trait :dessert do
      category { "dessert" }
      price { 8.99 }
      prep_time_minutes { 10 }
    end

    trait :without_image do
      image_url { nil }
    end
  end
end
