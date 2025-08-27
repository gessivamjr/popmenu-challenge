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
  end
end
