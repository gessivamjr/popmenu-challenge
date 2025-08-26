# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

if !Rails.env.production?
  MenuItem.destroy_all
  Menu.destroy_all
end

# Create sample dinner menu
dinner_menu = Menu.find_or_create_by!(name: "Dinner Menu") do |m|
  m.description = "Our signature dinner offerings featuring fresh pasta, wood-fired pizzas, and traditional Italian entrees."
  m.category = "Dinner"
  m.active = true
  m.starts_at = 17
  m.ends_at = 22
end

lunch_menu = Menu.find_or_create_by!(name: "Lunch Menu") do |m|
  m.description = "Light and delicious lunch options perfect for a midday break."
  m.category = "Lunch"
  m.active = true
  m.starts_at = 11
  m.ends_at = 15
end

# Create sample menu items for Dinner Menu
dinner_items = [
  {
    name: "Spaghetti Carbonara",
    description: "Traditional Roman pasta with eggs, pecorino cheese, pancetta, and black pepper.",
    category: "Pasta",
    price: 18.95,
    prep_time_minutes: 15,
    image_url: "https://placehold.co/150"
  },
  {
    name: "Margherita Pizza",
    description: "Classic Neapolitan pizza with San Marzano tomatoes, fresh mozzarella, and basil.",
    category: "Pizza",
    price: 16.50,
    prep_time_minutes: 12,
    image_url: "https://placehold.co/150"
  },
  {
    name: "Osso Buco",
    description: "Braised veal shanks with vegetables, white wine, and broth.",
    category: "Main Course",
    price: 32.00,
    prep_time_minutes: 25,
    image_url: "https://placehold.co/150"
  },
  {
    name: "Tiramisu",
    description: "Classic Italian dessert with coffee-soaked ladyfingers and mascarpone.",
    category: "Dessert",
    price: 9.95,
    prep_time_minutes: 5,
    image_url: "https://placehold.co/150"
  }
]

dinner_items.each do |item_attrs|
  MenuItem.find_or_create_by!(name: item_attrs[:name], menu: dinner_menu) do |item|
    item.description = item_attrs[:description]
    item.category = item_attrs[:category]
    item.price = item_attrs[:price]
    item.available = true
    item.prep_time_minutes = item_attrs[:prep_time_minutes]
    item.image_url = item_attrs[:image_url]
  end
end

# Create sample menu items for Lunch Menu
lunch_items = [
  {
    name: "Caprese Sandwich",
    description: "Fresh mozzarella, tomatoes, and basil on artisan bread with balsamic glaze.",
    category: "Sandwich",
    price: 12.95,
    prep_time_minutes: 8,
    image_url: "https://example.com/caprese-sandwich.jpg"
  },
  {
    name: "Caesar Salad",
    description: "Crisp romaine lettuce with house-made Caesar dressing, croutons, and parmesan.",
    category: "Salad",
    price: 11.50,
    prep_time_minutes: 5,
    image_url: "https://example.com/caesar-salad.jpg"
  },
  {
    name: "Minestrone Soup",
    description: "Traditional Italian vegetable soup with beans and pasta.",
    category: "Soup",
    price: 8.95,
    prep_time_minutes: 3,
    image_url: "https://example.com/minestrone.jpg"
  },
  {
    name: "Panettone Bread Pudding",
    description: "Sweet Italian bread pudding with vanilla sauce.",
    category: "Dessert",
    price: 7.95,
    prep_time_minutes: 5,
    image_url: "https://example.com/bread-pudding.jpg"
  }
]

lunch_items.each do |item_attrs|
  MenuItem.find_or_create_by!(name: item_attrs[:name], menu: lunch_menu) do |item|
    item.description = item_attrs[:description]
    item.category = item_attrs[:category]
    item.price = item_attrs[:price]
    item.available = true
    item.prep_time_minutes = item_attrs[:prep_time_minutes]
    item.image_url = item_attrs[:image_url]
  end
end

puts "Seeded database with:"
puts "- 2 Menus: #{dinner_menu.name}, #{lunch_menu.name}"
puts "- #{dinner_items.length + lunch_items.length} Menu Items total"
