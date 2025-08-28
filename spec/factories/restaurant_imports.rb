FactoryBot.define do
  factory :restaurant_import do
    status { "pending" }
    created_restaurants_count { 0 }
    created_menus_count { 0 }
    created_menu_items_count { 0 }
    linked_menu_items_count { 0 }
    failed_restaurants_count { 0 }
    failed_menus_count { 0 }
    failed_menu_items_count { 0 }
    failed_links_count { 0 }
    started_at { nil }
    finished_at { nil }
    error_message { nil }

    trait :pending do
      status { "pending" }
    end

    trait :processing do
      status { "processing" }
      started_at { 1.hour.ago }
    end

    trait :completed do
      status { "completed" }
      created_restaurants_count { 2 }
      created_menus_count { 3 }
      created_menu_items_count { 5 }
      linked_menu_items_count { 5 }
      failed_restaurants_count { 0 }
      failed_menus_count { 0 }
      failed_menu_items_count { 0 }
      failed_links_count { 0 }
      started_at { 2.hours.ago }
      finished_at { 1.hour.ago }
    end

    trait :failed do
      status { "failed" }
      created_restaurants_count { 1 }
      created_menus_count { 1 }
      created_menu_items_count { 2 }
      linked_menu_items_count { 1 }
      failed_restaurants_count { 1 }
      failed_menus_count { 1 }
      failed_menu_items_count { 1 }
      failed_links_count { 1 }
      started_at { 2.hours.ago }
      finished_at { 1.hour.ago }
      error_message { "Import failed due to validation errors" }
    end

    trait :with_valid_json_file do
      after(:build) do |restaurant_import|
        restaurant_import.file.attach(
          io: StringIO.new('{"restaurants": [{"name": "Test Restaurant", "address": "123 Main St"}]}'),
          filename: "restaurants.json",
          content_type: "application/json"
        )
      end
    end

    trait :with_text_json_file do
      after(:build) do |restaurant_import|
        restaurant_import.file.attach(
          io: StringIO.new('{"restaurants": [{"name": "Test Restaurant", "address": "123 Main St"}]}'),
          filename: "restaurants.json",
          content_type: "text/json"
        )
      end
    end

    trait :with_text_plain_file do
      after(:build) do |restaurant_import|
        restaurant_import.file.attach(
          io: StringIO.new('{"restaurants": [{"name": "Test Restaurant", "address": "123 Main St"}]}'),
          filename: "restaurants.json",
          content_type: "text/plain"
        )
      end
    end

    trait :with_invalid_json_file do
      after(:build) do |restaurant_import|
        restaurant_import.file.attach(
          io: StringIO.new('{"restaurants": [{"name": "Test Restaurant", "address":}]}'),
          filename: "restaurants.json",
          content_type: "application/json"
        )
      end
    end

    trait :with_non_json_extension do
      after(:build) do |restaurant_import|
        restaurant_import.file.attach(
          io: StringIO.new('{"restaurants": [{"name": "Test Restaurant", "address": "123 Main St"}]}'),
          filename: "restaurants.txt",
          content_type: "application/json"
        )
      end
    end

    trait :with_invalid_content_type do
      after(:build) do |restaurant_import|
        restaurant_import.file.attach(
          io: StringIO.new('{"restaurants": [{"name": "Test Restaurant", "address": "123 Main St"}]}'),
          filename: "restaurants.json",
          content_type: "application/pdf"
        )
      end
    end

    trait :with_empty_file do
      after(:build) do |restaurant_import|
        restaurant_import.file.attach(
          io: StringIO.new(''),
          filename: "restaurants.json",
          content_type: "application/json"
        )
      end
    end

    trait :with_large_file do
      after(:build) do |restaurant_import|
        large_content = { restaurants: Array.new(1000) { |i| { name: "Restaurant #{i}", address: "#{i} Main St" } } }.to_json
        restaurant_import.file.attach(
          io: StringIO.new(large_content),
          filename: "large_restaurants.json",
          content_type: "application/json"
        )
      end
    end

    trait :with_special_chars_filename do
      after(:build) do |restaurant_import|
        restaurant_import.file.attach(
          io: StringIO.new('{"restaurants": [{"name": "Test Restaurant", "address": "123 Main St"}]}'),
          filename: "restaurants with spaces & special-chars.json",
          content_type: "application/json"
        )
      end
    end
  end
end
