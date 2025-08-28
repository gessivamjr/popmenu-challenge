FactoryBot.define do
  factory :menu_menu_item do
    association :menu
    association :menu_item
    price { 12.99 }
    currency { "USD" }
    available { true }
    description { "Delicious menu item" }
    category { "Main Course" }
    image_url { "https://example.com/item.jpg" }
    prep_time_minutes { 15 }

    trait :beverage do
      category { "Beverage" }
      price { 4.99 }
      prep_time_minutes { 5 }
    end

    trait :side_dish do
      category { "Side Dish" }
      price { 7.99 }
      prep_time_minutes { 10 }
    end

    trait :expensive do
      price { 55.99 }
    end

    trait :cheap do
      price { 3.99 }
    end

    trait :unavailable do
      available { false }
    end

    trait :complete do
      description { "Complete menu item with all details" }
      image_url { "https://example.com/complete-item.jpg" }
      prep_time_minutes { 25 }
    end
  end
end
