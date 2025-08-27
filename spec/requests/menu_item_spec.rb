require 'rails_helper'

RSpec.describe "MenuItems", type: :request do
  let(:restaurant) { create(:restaurant) }
  let(:menu) { create(:menu, restaurant: restaurant) }
  let(:menu_item) { create(:menu_item, :with_menu, menu: menu) }
  let(:other_restaurant) { create(:restaurant) }
  let(:other_menu) { create(:menu, restaurant: other_restaurant) }

  describe "GET /restaurant/:restaurant_id/menu/:menu_id/menu_item" do
    context "when menu exists" do
      context "when menu has menu items" do
        let!(:menu_items) { create_list(:menu_item, 4, :with_menu, menu: menu) }

        it "returns all menu items for the menu" do
          get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item"

          expect(response).to have_http_status(:ok)
          expect(json).to be_an(Array)
          expect(json.length).to eq(4)
        end

        it "returns menu items with all attributes" do
          menu_item = menu_items.first

          get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item"

          item_response = json.find { |item| item['id'] == menu_item.id }
          expect(item_response['name']).to eq(menu_item.name)
          expect(item_response['price']).to eq(menu_item.price.to_s)
          expect(item_response['category']).to eq(menu_item.category)
          expect(item_response['available']).to eq(menu_item.available)
          expect(item_response['description']).to eq(menu_item.description)
          expect(item_response['currency']).to eq(menu_item.currency)
        end
      end

      context "when menu has no menu items" do
        it "returns an empty array" do
          get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item"

          expect(response).to have_http_status(:ok)
          expect(json).to eq([])
        end
      end
    end

    context "when menu does not exist" do
      it "returns not found error" do
        get "/restaurant/#{restaurant.id}/menu/99999/menu_item"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        get "/restaurant/99999/menu/#{menu.id}/menu_item"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end
  end

  describe "GET /restaurant/:restaurant_id/menu/:menu_id/menu_item/:id" do
    context "when menu item exists" do
      it "returns the menu item" do
        get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item.id}"

        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(menu_item.id)
        expect(json['name']).to eq(menu_item.name)
        expect(json['description']).to eq(menu_item.description)
        expect(json['price']).to eq(menu_item.price.to_s)
        expect(json['category']).to eq(menu_item.category)
        expect(json['available']).to eq(menu_item.available)
        expect(json['currency']).to eq(menu_item.currency)
      end

      it "returns menu item with all optional fields" do
        detailed_item = create(:menu_item, :main_course, :with_menu,
                              menu: menu,
                              image_url: "https://example.com/food.jpg",
                              prep_time_minutes: 25)

        get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{detailed_item.id}"

        expect(json['image_url']).to eq("https://example.com/food.jpg")
        expect(json['prep_time_minutes']).to eq(25)
        expect(json['category']).to eq("main_course")
      end

      it "returns unavailable menu item" do
        unavailable_item = create(:menu_item, :unavailable, :with_menu, menu: menu)

        get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{unavailable_item.id}"

        expect(json['available']).to eq(false)
      end

      it "returns menu item with different price formats" do
        expensive_item = create(:menu_item, :expensive, :with_menu, menu: menu)

        get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{expensive_item.id}"

        expect(json['price']).to eq("100.99")
      end
    end

    context "when menu item does not exist" do
      it "returns not found error" do
        get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/99999"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end

    context "when menu does not exist" do
      it "returns not found error" do
        get "/restaurant/#{restaurant.id}/menu/99999/menu_item/#{menu_item.id}"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        get "/restaurant/99999/menu/#{menu.id}/menu_item/#{menu_item.id}"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end

    context "when menu item belongs to different menu" do
      let(:other_menu_item) { create(:menu_item, :with_menu, menu: other_menu) }

      it "returns not found error" do
        get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{other_menu_item.id}"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end
  end

  describe "POST /restaurant/:restaurant_id/menu/:menu_id/menu_item" do
    let(:valid_attributes) do
      {
        name: "Grilled Salmon",
        description: "Fresh Atlantic salmon with herbs",
        category: "main_course",
        price: 24.99,
        currency: "USD",
        available: true,
        image_url: "https://example.com/salmon.jpg",
        prep_time_minutes: 20
      }
    end

    context "with valid parameters" do
      it "creates a new menu item" do
        expect {
          post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: valid_attributes
        }.to change(MenuItem, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("Grilled Salmon")
      end

      it "returns the created menu item" do
        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: valid_attributes

        expect(json['name']).to eq(valid_attributes[:name])
        expect(json['description']).to eq(valid_attributes[:description])
        expect(json['category']).to eq(valid_attributes[:category])
        expect(json['price']).to eq(valid_attributes[:price].to_s)
        expect(json['currency']).to eq(valid_attributes[:currency])
        expect(json['available']).to eq(valid_attributes[:available])
      end

      it "creates menu item with minimal required data" do
        minimal_attributes = {
          name: "Simple Dish",
          category: "appetizer",
          price: 8.99,
          currency: "USD"
        }

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: minimal_attributes

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("Simple Dish")
        expect(json['description']).to be_nil
        expect(json['available']).to eq(true)
        expect(json['currency']).to eq("USD")
      end

      it "handles all optional fields" do
        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: valid_attributes

        expect(json['image_url']).to eq(valid_attributes[:image_url])
        expect(json['prep_time_minutes']).to eq(valid_attributes[:prep_time_minutes])
      end
    end

    context "with invalid parameters" do
      it "returns validation errors when name is missing" do
        invalid_attributes = valid_attributes.except(:name)

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name can't be blank")
      end

      it "returns validation errors when price is missing" do
        invalid_attributes = valid_attributes.except(:price)

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Price can't be blank")
      end

      it "uses default currency when not provided" do
        attributes_without_currency = valid_attributes.except(:currency)

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: attributes_without_currency

        expect(response).to have_http_status(:created)
        expect(json['currency']).to eq("USD")
      end

      it "returns validation errors for negative price" do
        invalid_attributes = valid_attributes.merge(price: -5.00)

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Price must be greater than or equal to 0")
      end

      it "returns multiple validation errors" do
        invalid_attributes = { description: "Just a description" }

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name can't be blank")
        expect(json['errors']).to include("Price can't be blank")
      end
    end

    context "when menu does not exist" do
      it "returns not found error" do
        post "/restaurant/#{restaurant.id}/menu/99999/menu_item", params: valid_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        post "/restaurant/99999/menu/#{menu.id}/menu_item", params: valid_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end
  end

  describe "PATCH /restaurant/:restaurant_id/menu/:menu_id/menu_item/:id" do
    let(:update_attributes) do
      {
        name: "Updated Dish Name",
        description: "Updated description with new details",
        price: 29.99,
        available: false
      }
    end

    context "when menu item exists" do
      it "updates the menu item" do
        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item.id}", params: update_attributes

        expect(response).to have_http_status(:ok)
        expect(json['name']).to eq("Updated Dish Name")
        expect(json['description']).to eq("Updated description with new details")
        expect(json['price']).to eq("29.99")
        expect(json['available']).to eq(false)
      end

      it "updates only provided attributes" do
        original_category = menu_item.category
        partial_update = { name: "New Name Only" }

        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item.id}", params: partial_update

        expect(response).to have_http_status(:ok)
        expect(json['name']).to eq("New Name Only")
        expect(json['category']).to eq(original_category)
      end

      it "updates availability status" do
        availability_update = { available: false }

        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item.id}", params: availability_update

        expect(response).to have_http_status(:ok)
        expect(json['available']).to eq(false)
      end

      it "updates price and prep time" do
        price_update = { price: 35.50, prep_time_minutes: 30 }

        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item.id}", params: price_update

        expect(response).to have_http_status(:ok)
        expect(json['price']).to eq("35.5")
        expect(json['prep_time_minutes']).to eq(30)
      end

      it "updates currency" do
        currency_update = { currency: "EUR" }

        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item.id}", params: currency_update

        expect(response).to have_http_status(:ok)
        expect(json['currency']).to eq("EUR")
      end

      it "updates image_url" do
        image_update = { image_url: "https://example.com/new-image.jpg" }

        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item.id}", params: image_update

        expect(response).to have_http_status(:ok)
        expect(json['image_url']).to eq("https://example.com/new-image.jpg")
      end

      it "validates updated attributes" do
        invalid_update = { name: "", price: -10.00 }

        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item.id}", params: invalid_update

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name can't be blank")
        expect(json['errors']).to include("Price must be greater than or equal to 0")
      end
    end

    context "when menu item does not exist" do
      it "returns not found error" do
        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/99999", params: update_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end

    context "when menu does not exist" do
      it "returns not found error" do
        patch "/restaurant/#{restaurant.id}/menu/99999/menu_item/#{menu_item.id}", params: update_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        patch "/restaurant/99999/menu/#{menu.id}/menu_item/#{menu_item.id}", params: update_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end

    context "when menu item belongs to different menu" do
      let(:other_menu_item) { create(:menu_item, :with_menu, menu: other_menu) }

      it "returns not found error" do
        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{other_menu_item.id}", params: update_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end
  end

  describe "DELETE /restaurant/:restaurant_id/menu/:menu_id/menu_item/:id" do
    context "when menu item exists" do
      let!(:menu_item_to_delete) { create(:menu_item, :with_menu, menu: menu) }

      it "deletes the menu item" do
        expect {
          delete "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item_to_delete.id}"
        }.to change(MenuItem, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(json['message']).to eq("Menu item deleted successfully")
      end

      it "does not affect other menu items" do
        other_menu_item = create(:menu_item, :with_menu, menu: menu)

        delete "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item_to_delete.id}"

        expect(response).to have_http_status(:ok)
        expect(MenuItem.find_by(id: other_menu_item.id)).to be_present
      end

      it "does not affect menu items from other menus" do
        other_menu_item = create(:menu_item, :with_menu, menu: other_menu)

        delete "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item_to_delete.id}"

        expect(response).to have_http_status(:ok)
        expect(MenuItem.find_by(id: other_menu_item.id)).to be_present
      end
    end

    context "when menu item does not exist" do
      it "returns not found error" do
        delete "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/99999"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end

    context "when menu does not exist" do
      it "returns not found error" do
        delete "/restaurant/#{restaurant.id}/menu/99999/menu_item/#{menu_item.id}"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        delete "/restaurant/99999/menu/#{menu.id}/menu_item/#{menu_item.id}"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end

    context "when menu item belongs to different menu" do
      let(:other_menu_item) { create(:menu_item, :with_menu, menu: other_menu) }

      it "returns not found error" do
        delete "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{other_menu_item.id}"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end
  end

  describe "Edge cases" do
    context "with special characters in parameters" do
      it "handles special characters in menu item names" do
        special_attributes = {
          name: "Café au Lait & Crème Brûlée™",
          description: "Special chars: àáâãäåæçèéêë",
          category: "dessert",
          price: 12.50,
          currency: "USD"
        }

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: special_attributes

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("Café au Lait & Crème Brûlée™")
        expect(json['description']).to eq("Special chars: àáâãäåæçèéêë")
      end
    end

    context "with extreme price values" do
      it "handles very high prices" do
        high_price_attributes = {
          name: "Expensive Dish",
          category: "main",
          price: 999.99,
          currency: "USD"
        }

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: high_price_attributes

        expect(response).to have_http_status(:created)
        expect(json['price']).to eq("999.99")
      end

      it "handles very low prices" do
        low_price_attributes = {
          name: "Cheap Dish",
          category: "appetizer",
          price: 0.01,
          currency: "USD"
        }

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: low_price_attributes

        expect(response).to have_http_status(:created)
        expect(json['price']).to eq("0.01")
      end

      it "handles zero price" do
        zero_price_attributes = {
          name: "Free Sample",
          category: "appetizer",
          price: 0.00,
          currency: "USD"
        }

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: zero_price_attributes

        expect(response).to have_http_status(:created)
        expect(json['price']).to eq("0.0")
      end
    end

    context "with long text fields" do
      it "handles very long descriptions" do
        long_description = "A" * 500
        long_text_attributes = {
          name: "Detailed Dish",
          description: long_description,
          category: "main",
          price: 25.00,
          currency: "USD"
        }

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: long_text_attributes

        expect(response).to have_http_status(:created)
        expect(json['description']).to eq(long_description)
      end

      it "handles very long names" do
        long_name = "Super " * 20 + "Long Dish Name"
        long_name_attributes = {
          name: long_name,
          category: "main",
          price: 25.00,
          currency: "USD"
        }

        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: long_name_attributes

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq(long_name)
      end
    end

    context "with different category types" do
      it "creates menu items with different categories" do
        categories = [ "appetizer", "main_course", "dessert", "beverage", "side" ]

        categories.each_with_index do |category, index|
          attributes = {
            name: "#{category.humanize} Item #{index}",
            category: category,
            price: (10 + index * 5).to_f,
            currency: "USD"
          }

          post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: attributes

          expect(response).to have_http_status(:created)
          expect(json['category']).to eq(category)
        end
      end
    end

    context "with different currencies" do
      it "creates menu items with different currencies" do
        currencies = [ "USD", "EUR", "GBP", "JPY", "CAD" ]

        currencies.each_with_index do |currency, index|
          attributes = {
            name: "#{currency} Item #{index}",
            category: "main",
            price: 25.00,
            currency: currency
          }

          post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: attributes

          expect(response).to have_http_status(:created)
          expect(json['currency']).to eq(currency)
        end
      end
    end

    context "with boolean values" do
      it "handles false availability correctly" do
        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: {
          name: "Unavailable Item",
          category: "main",
          price: 20.00,
          currency: "USD",
          available: false
        }

        expect(response).to have_http_status(:created)
        expect(json['available']).to eq(false)
      end

      it "handles nil/missing availability (defaults to true)" do
        post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: {
          name: "Default Available Item",
          category: "main",
          price: 20.00,
          currency: "USD"
        }

        expect(response).to have_http_status(:created)
        expect(json['available']).to eq(true)
      end
    end
  end

  describe "Data consistency and associations" do
    it "maintains menu association correctly" do
      created_item_id = nil

      post "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item", params: {
        name: "Test Item",
        category: "main",
        price: 15.99,
        currency: "USD"
      }

      created_item_id = json['id']

      get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item"

      expect(json.any? { |item| item['id'] == created_item_id }).to be true
    end

    it "maintains proper isolation between menus" do
      menu1_item = create(:menu_item, :with_menu, menu: menu, name: "Menu 1 Item")
      menu2_item = create(:menu_item, :with_menu, menu: other_menu, name: "Menu 2 Item")

      get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item"
      menu1_items = json

      get "/restaurant/#{other_restaurant.id}/menu/#{other_menu.id}/menu_item"
      menu2_items = json

      expect(menu1_items.any? { |item| item['id'] == menu1_item.id }).to be true
      expect(menu1_items.any? { |item| item['id'] == menu2_item.id }).to be false

      expect(menu2_items.any? { |item| item['id'] == menu2_item.id }).to be true
      expect(menu2_items.any? { |item| item['id'] == menu1_item.id }).to be false
    end

    it "handles concurrent operations safely" do
      menu_item_to_delete = create(:menu_item, :with_menu, menu: menu)
      other_items = create_list(:menu_item, 3, :with_menu, menu: menu)

      delete "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item/#{menu_item_to_delete.id}"
      expect(response).to have_http_status(:ok)

      get "/restaurant/#{restaurant.id}/menu/#{menu.id}/menu_item"
      remaining_ids = json.map { |item| item['id'] }

      expect(remaining_ids).not_to include(menu_item_to_delete.id)
      other_items.each do |item|
        expect(remaining_ids).to include(item.id)
      end
    end
  end
end
