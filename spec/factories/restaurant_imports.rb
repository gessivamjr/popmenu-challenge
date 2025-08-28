FactoryBot.define do
  factory :restaurant_import do
    status { "pending" }
    total_count { 0 }
    success_count { 0 }
    failure_count { 0 }
    started_at { nil }
    finished_at { nil }
    error_message { nil }

    trait :processing do
      status { "processing" }
      started_at { 1.hour.ago }
    end

    trait :completed do
      status { "completed" }
      total_count { 5 }
      success_count { 5 }
      failure_count { 0 }
      started_at { 2.hours.ago }
      finished_at { 1.hour.ago }
    end

    trait :failed do
      status { "failed" }
      total_count { 3 }
      success_count { 1 }
      failure_count { 2 }
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
