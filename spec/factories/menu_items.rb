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

    trait :unavailable do
      available { false }
    end

    trait :cheap do
      price { 9.99 }
    end

    trait :expensive do
      price { 100.99 }
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

    trait :with_menu do
      after(:create) do |menu_item, evaluator|
        menu = evaluator.menu || create(:menu)
        menu.menu_items << menu_item
      end
    end

    transient do
      menu { nil }
    end

    trait :beverage do
      category { "beverage" }
      price { 4.99 }
      prep_time_minutes { 5 }
    end

    trait :side_dish do
      category { "side" }
      price { 6.99 }
      prep_time_minutes { 8 }
    end

    trait :complete do
      name { "Premium Dish" }
      description { "A complete dish with all details" }
      category { "main_course" }
      price { 28.99 }
      currency { "USD" }
      available { true }
      prep_time_minutes { 30 }
      image_url { "https://example.com/premium-dish.jpg" }
    end
  end
end
