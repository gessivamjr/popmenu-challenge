# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

if !Rails.env.production?
  MenuMenuItem.destroy_all
  MenuItem.destroy_all
  Menu.destroy_all
  Restaurant.destroy_all
end

restaurant = Restaurant.find_or_create_by!(name: "Tony's Italian Bistro") do |r|
  r.description = "Authentic Italian cuisine in the heart of downtown. Family-owned restaurant serving traditional recipes passed down through generations."
  r.address_line_1 = "123 Main Street"
  r.address_line_2 = "Suite 100"
  r.city = "San Francisco"
  r.state = "CA"
  r.zip_code = "94102"
  r.phone_number = "(415) 555-0123"
  r.email = "info@example.com"
  r.website_url = "https://www.example.com/tonys-italian-bistro"
  r.logo_url = "https://placehold.co/150"
  r.cover_image_url = "https://placehold.co/600x400"
end

dinner_menu = Menu.find_or_create_by!(name: "Dinner Menu", restaurant: restaurant) do |m|
  m.description = "Our signature dinner offerings featuring fresh pasta, wood-fired pizzas, and traditional Italian entrees."
  m.category = "Dinner"
  m.active = true
  m.starts_at = 17
  m.ends_at = 22
end

lunch_menu = Menu.find_or_create_by!(name: "Lunch Menu", restaurant: restaurant) do |m|
  m.description = "Light and delicious lunch options perfect for a midday break."
  m.category = "Lunch"
  m.active = true
  m.starts_at = 11
  m.ends_at = 15
end

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
  item = MenuItem.find_or_create_by!(name: item_attrs[:name])

  unless dinner_menu.menu_menu_items.exists?(menu_item: item)
    MenuMenuItem.create!(
      menu: dinner_menu,
      menu_item: item,
      description: item_attrs[:description],
      category: item_attrs[:category],
      price: item_attrs[:price],
      currency: "USD",
      available: true,
      prep_time_minutes: item_attrs[:prep_time_minutes],
      image_url: item_attrs[:image_url]
    )
  end
end

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
  item = MenuItem.find_or_create_by!(name: item_attrs[:name])

  unless lunch_menu.menu_menu_items.exists?(menu_item: item)
    MenuMenuItem.create!(
      menu: lunch_menu,
      menu_item: item,
      description: item_attrs[:description],
      category: item_attrs[:category],
      price: item_attrs[:price],
      currency: "USD",
      available: true,
      prep_time_minutes: item_attrs[:prep_time_minutes],
      image_url: item_attrs[:image_url]
    )
  end
end

shared_items = [ "Tiramisu", "Caesar Salad" ]
shared_items.each do |item_name|
  item = MenuItem.find_by(name: item_name)
  if item
    dinner_link = dinner_menu.menu_menu_items.find_by(menu_item: item)
    lunch_link = lunch_menu.menu_menu_items.find_by(menu_item: item)

    if dinner_link && !lunch_link
      MenuMenuItem.create!(
        menu: lunch_menu,
        menu_item: item,
        description: dinner_link.description,
        category: dinner_link.category,
        price: dinner_link.price,
        currency: dinner_link.currency,
        available: dinner_link.available,
        prep_time_minutes: dinner_link.prep_time_minutes,
        image_url: dinner_link.image_url
      )
    elsif lunch_link && !dinner_link
      MenuMenuItem.create!(
        menu: dinner_menu,
        menu_item: item,
        description: lunch_link.description,
        category: lunch_link.category,
        price: lunch_link.price,
        currency: lunch_link.currency,
        available: lunch_link.available,
        prep_time_minutes: lunch_link.prep_time_minutes,
        image_url: lunch_link.image_url
      )
    end
  end
end

puts "Seeded database with:"
puts "- 1 Restaurant: #{restaurant.name}"
puts "- 2 Menus: #{dinner_menu.name}, #{lunch_menu.name}"
puts "- #{MenuItem.count} unique Menu Items total"
puts "- #{MenuMenuItem.count} total Menu-Item links"
puts "- #{dinner_menu.menu_menu_items.count} items on #{dinner_menu.name}"
puts "- #{lunch_menu.menu_menu_items.count} items on #{lunch_menu.name}"
puts "- Shared items (on both menus): #{shared_items.join(', ')}"
