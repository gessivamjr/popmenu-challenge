FactoryBot.define do
  factory :restaurant do
    sequence(:name) { |n| "Restaurant #{n}" }
    description { "A great restaurant" }
    address_line_1 { "123 Main St" }
    city { "San Francisco" }
    state { "CA" }
    zip_code { "94102" }
    phone_number { "(415) 555-0123" }
    email { "info@restaurant.com" }
    website_url { "https://www.restaurant.com" }
    logo_url { "https://example.com/logo.png" }
    cover_image_url { "https://example.com/cover.png" }

    trait :minimal do
      description { nil }
      address_line_1 { nil }
      address_line_2 { nil }
      city { nil }
      state { nil }
      zip_code { nil }
      phone_number { nil }
      email { nil }
      website_url { nil }
      logo_url { nil }
      cover_image_url { nil }
    end

    trait :with_menus do
      after(:create) do |restaurant|
        create_list(:menu, 3, restaurant: restaurant)
      end
    end

    trait :with_menu_items do
      after(:create) do |restaurant|
        menus = create_list(:menu, 3, restaurant: restaurant)

        menus.each do |menu|
          menu_items = create_list(:menu_item, 2)
          menu.menu_items << menu_items
        end
      end
    end
  end
end
