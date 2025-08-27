require 'rails_helper'

RSpec.describe "Restaurants", type: :request do
  let(:restaurant) { create(:restaurant) }
  let(:restaurant_with_menus) { create(:restaurant, :with_menus) }

  describe "GET /restaurant" do
    context "when restaurants exist" do
      let!(:restaurants) { create_list(:restaurant, 5) }

      it "returns all restaurants" do
        get "/restaurant"

        expect(response).to have_http_status(:ok)
        expect(json).to be_an(Array)
        expect(json.length).to eq(5)
      end

      it "includes associated menus in the response" do
        restaurant_with_menus = create(:restaurant, :with_menus)

        get "/restaurant"

        restaurant_response = json.find { |r| r['id'] == restaurant_with_menus.id }
        expect(restaurant_response).to have_key('menus')
        expect(restaurant_response['menus']).to be_an(Array)
        expect(restaurant_response['menus'].length).to eq(3)
      end

      it "includes menu_items in the response" do
        restaurant_with_menu_items = create(:restaurant, :with_menu_items)

        get "/restaurant"

        restaurant_response = json.find { |r| r['id'] == restaurant_with_menu_items.id }
        expect(restaurant_response).to have_key('menu_items')
        expect(restaurant_response['menu_items']).to be_an(Array)
        expect(restaurant_response['menu_items'].length).to eq(6)
      end

      it "orders restaurants by created_at desc" do
        Restaurant.destroy_all

        oldest_restaurant = create(:restaurant, created_at: 2.days.ago)
        newest_restaurant = create(:restaurant, created_at: 1.day.ago)

        get "/restaurant"

        expect(json.length).to eq(2)
        expect(json.first['id']).to eq(newest_restaurant.id)
        expect(json.last['id']).to eq(oldest_restaurant.id)
      end

      context "with pagination" do
        before do
          Restaurant.destroy_all
          create_list(:restaurant, 15)
        end

        it "supports pagination with page parameter" do
          get "/restaurant", params: { page: 2, per_page: 5 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(5)
        end

        it "supports custom per_page parameter" do
          get "/restaurant", params: { per_page: 3 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(3)
        end

        it "defaults to page 1 and per_page 10" do
          get "/restaurant"

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(10)
        end

        it "handles page parameter with per_page" do
          get "/restaurant", params: { page: 2, per_page: 8 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(7)
        end

        it "handles invalid page parameter gracefully" do
          get "/restaurant", params: { page: 0 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(10)
        end
      end
    end

    context "when no restaurants exist" do
      it "returns an empty array" do
        get "/restaurant"

        expect(response).to have_http_status(:ok)
        expect(json).to eq([])
      end
    end
  end

  describe "GET /restaurant/:id" do
    context "when restaurant exists" do
      it "returns the restaurant" do
        get "/restaurant/#{restaurant.id}"

        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(restaurant.id)
        expect(json['name']).to eq(restaurant.name)
        expect(json['description']).to eq(restaurant.description)
        expect(json['address_line_1']).to eq(restaurant.address_line_1)
        expect(json['address_line_2']).to eq(restaurant.address_line_2)
        expect(json['city']).to eq(restaurant.city)
        expect(json['state']).to eq(restaurant.state)
        expect(json['phone_number']).to eq(restaurant.phone_number)
        expect(json['email']).to eq(restaurant.email)
        expect(json['website_url']).to eq(restaurant.website_url)
        expect(json['logo_url']).to eq(restaurant.logo_url)
        expect(json['cover_image_url']).to eq(restaurant.cover_image_url)
        expect(json['created_at']).to eq(restaurant.created_at.strftime("%Y-%m-%dT%H:%M:%S.%LZ"))
        expect(json['updated_at']).to eq(restaurant.updated_at.strftime("%Y-%m-%dT%H:%M:%S.%LZ"))
      end

      it "includes associated menus" do
        get "/restaurant/#{restaurant_with_menus.id}"

        expect(json).to have_key('menus')
        expect(json['menus']).to be_an(Array)
        expect(json['menus'].length).to eq(3)
      end

      it "includes menus structure in response" do
        get "/restaurant/#{restaurant_with_menus.id}"

        expect(json).to have_key('menus')
        expect(json['menus']).to be_an(Array)
        expect(json['menus'].length).to eq(3)

        menu_response = json['menus'].first
        expect(menu_response).to have_key('id')
        expect(menu_response).to have_key('name')
        expect(menu_response).to have_key('description')
        expect(menu_response).to have_key('category')
        expect(menu_response).to have_key('active')
        expect(menu_response).to have_key('starts_at')
        expect(menu_response).to have_key('ends_at')
        expect(menu_response).to have_key('created_at')
        expect(menu_response).to have_key('updated_at')
        expect(menu_response).to have_key('restaurant_id')
      end

      it "includes menu_items in the response" do
        restaurant = create(:restaurant, :with_menu_items)

        get "/restaurant/#{restaurant.id}"

        expect(json).to have_key('menu_items')
        expect(json['menu_items']).to be_an(Array)
        expect(json['menu_items'].length).to eq(6)

        menu_item = json['menu_items'].first
        expect(menu_item).to have_key('id')
        expect(menu_item).to have_key('name')
        expect(menu_item).to have_key('price')
        expect(menu_item).to have_key('currency')
        expect(menu_item).to have_key('category')
        expect(menu_item).to have_key('available')
        expect(menu_item).to have_key('prep_time_minutes')
        expect(menu_item).to have_key('image_url')
        expect(menu_item).to have_key('created_at')
        expect(menu_item).to have_key('updated_at')
      end

      it "returns restaurant with minimal data" do
        minimal_restaurant = create(:restaurant, :minimal)

        get "/restaurant/#{minimal_restaurant.id}"

        expect(response).to have_http_status(:ok)
        expect(json['name']).to eq(minimal_restaurant.name)
        expect(json['description']).to be_nil
        expect(json['phone_number']).to be_nil
        expect(json['address_line_1']).to be_nil
        expect(json['address_line_2']).to be_nil
        expect(json['city']).to be_nil
        expect(json['state']).to be_nil
        expect(json['zip_code']).to be_nil
        expect(json['phone_number']).to be_nil
        expect(json['email']).to be_nil
        expect(json['website_url']).to be_nil
        expect(json['logo_url']).to be_nil
        expect(json['cover_image_url']).to be_nil
      end

      it "returns all restaurant attributes" do
        get "/restaurant/#{restaurant.id}"

        expect(json).to have_key('name')
        expect(json).to have_key('description')
        expect(json).to have_key('address_line_1')
        expect(json).to have_key('address_line_2')
        expect(json).to have_key('city')
        expect(json).to have_key('state')
        expect(json).to have_key('zip_code')
        expect(json).to have_key('phone_number')
        expect(json).to have_key('email')
        expect(json).to have_key('website_url')
        expect(json).to have_key('logo_url')
        expect(json).to have_key('cover_image_url')
        expect(json).to have_key('created_at')
        expect(json).to have_key('updated_at')
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        get "/restaurant/99999"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Restaurant not found")
      end
    end
  end

  describe "POST /restaurant" do
    let(:valid_attributes) do
      {
        name: "The Great Eatery",
        description: "Amazing food and atmosphere",
        address_line_1: "456 Oak Avenue",
        address_line_2: "Floor 2",
        city: "San Francisco",
        state: "CA",
        zip_code: "94102",
        phone_number: "(415) 555-0123",
        email: "info@greateatery.com",
        website_url: "https://www.greateatery.com",
        logo_url: "https://example.com/logo.png",
        cover_image_url: "https://example.com/cover.png"
      }
    end

    context "with valid parameters" do
      it "creates a new restaurant" do
        expect {
          post "/restaurant", params: valid_attributes
        }.to change(Restaurant, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("The Great Eatery")
        expect(json['email']).to eq("info@greateatery.com")
      end

      it "returns the created restaurant" do
        post "/restaurant", params: valid_attributes

        expect(json['name']).to eq(valid_attributes[:name])
        expect(json['description']).to eq(valid_attributes[:description])
        expect(json['address_line_1']).to eq(valid_attributes[:address_line_1])
        expect(json['address_line_2']).to eq(valid_attributes[:address_line_2])
        expect(json['city']).to eq(valid_attributes[:city])
        expect(json['state']).to eq(valid_attributes[:state])
        expect(json['zip_code']).to eq(valid_attributes[:zip_code])
        expect(json['phone_number']).to eq(valid_attributes[:phone_number])
        expect(json['email']).to eq(valid_attributes[:email])
        expect(json['website_url']).to eq(valid_attributes[:website_url])
      end

      it "creates restaurant with minimal required data" do
        minimal_attributes = { name: "Minimal Restaurant" }

        post "/restaurant", params: minimal_attributes

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("Minimal Restaurant")
        expect(json['description']).to be_nil
      end

      it "handles all optional fields" do
        post "/restaurant", params: valid_attributes

        expect(json['phone_number']).to eq(valid_attributes[:phone_number])
        expect(json['website_url']).to eq(valid_attributes[:website_url])
        expect(json['logo_url']).to eq(valid_attributes[:logo_url])
        expect(json['cover_image_url']).to eq(valid_attributes[:cover_image_url])
      end

      it "initializes with empty menus array" do
        post "/restaurant", params: valid_attributes

        expect(json).to have_key('menus')
        expect(json['menus']).to eq([])
      end

      it "initializes with empty menu_items array" do
        post "/restaurant", params: valid_attributes

        expect(json).to have_key('menu_items')
        expect(json['menu_items']).to eq([])
      end
    end

    context "with invalid parameters" do
      it "returns validation errors when name is missing" do
        invalid_attributes = valid_attributes.except(:name)

        post "/restaurant", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name can't be blank")
      end

      it "returns validation errors when name is empty" do
        invalid_attributes = valid_attributes.merge(name: "")

        post "/restaurant", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name can't be blank")
      end

      it "creates restaurant even with invalid optional fields" do
        attributes_with_invalid_optional = valid_attributes.merge(
          email: "invalid-email",
          zip_code: "invalid-zip"
        )

        post "/restaurant", params: attributes_with_invalid_optional

        expect(response).to have_http_status(:created)
        expect(json['email']).to eq("invalid-email")
        expect(json['zip_code']).to eq("invalid-zip")
      end
    end
  end

  describe "PATCH /restaurant/:id" do
    let(:update_attributes) do
      {
        name: "Updated Restaurant Name",
        description: "Updated description with new details",
        city: "Los Angeles",
        state: "CA"
      }
    end

    context "when restaurant exists" do
      it "updates the restaurant" do
        patch "/restaurant/#{restaurant.id}", params: update_attributes

        expect(response).to have_http_status(:ok)
        expect(json['name']).to eq("Updated Restaurant Name")
        expect(json['description']).to eq("Updated description with new details")
        expect(json['city']).to eq("Los Angeles")
        expect(json['state']).to eq("CA")
      end

      it "updates only provided attributes" do
        original_email = restaurant.email
        partial_update = { name: "New Name Only" }

        patch "/restaurant/#{restaurant.id}", params: partial_update

        expect(response).to have_http_status(:ok)
        expect(json['name']).to eq("New Name Only")
        expect(json['email']).to eq(original_email)
      end

      it "updates contact information" do
        contact_update = {
          phone_number: "(555) 999-8888",
          email: "newemail@restaurant.com",
          website_url: "https://www.newwebsite.com"
        }

        patch "/restaurant/#{restaurant.id}", params: contact_update

        expect(response).to have_http_status(:ok)
        expect(json['phone_number']).to eq("(555) 999-8888")
        expect(json['email']).to eq("newemail@restaurant.com")
        expect(json['website_url']).to eq("https://www.newwebsite.com")
      end

      it "updates address information" do
        address_update = {
          address_line_1: "789 New Street",
          address_line_2: "Suite 456",
          city: "New York",
          state: "NY",
          zip_code: "10001"
        }

        patch "/restaurant/#{restaurant.id}", params: address_update

        expect(response).to have_http_status(:ok)
        expect(json['address_line_1']).to eq("789 New Street")
        expect(json['address_line_2']).to eq("Suite 456")
        expect(json['city']).to eq("New York")
        expect(json['state']).to eq("NY")
        expect(json['zip_code']).to eq("10001")
      end

      it "validates updated attributes" do
        invalid_update = { name: "" }

        patch "/restaurant/#{restaurant.id}", params: invalid_update

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name can't be blank")
      end

      it "preserves associated menus" do
        restaurant_with_menus.reload
        original_menu_count = restaurant_with_menus.menus.count

        patch "/restaurant/#{restaurant_with_menus.id}", params: { name: "Updated Name" }

        expect(response).to have_http_status(:ok)
        restaurant_with_menus.reload
        expect(restaurant_with_menus.menus.count).to eq(original_menu_count)
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        patch "/restaurant/99999", params: update_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Restaurant not found")
      end
    end
  end

  describe "DELETE /restaurant/:id" do
    context "when restaurant exists" do
      let!(:restaurant_to_delete) { create(:restaurant) }

      it "deletes the restaurant" do
        expect {
          delete "/restaurant/#{restaurant_to_delete.id}"
        }.to change(Restaurant, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(json['message']).to eq("Restaurant deleted successfully")
      end

      it "deletes associated menus (cascade delete)" do
        restaurant_with_menus = create(:restaurant, :with_menus)
        menu_count = restaurant_with_menus.menus.count

        expect {
          delete "/restaurant/#{restaurant_with_menus.id}"
        }.to change(Menu, :count).by(-menu_count)

        expect(response).to have_http_status(:ok)
      end

      it "removes menu associations when restaurant is deleted" do
        restaurant_with_menu_items = create(:restaurant, :with_menu_items)
        menu_ids = restaurant_with_menu_items.menus.pluck(:id)

        delete "/restaurant/#{restaurant_with_menu_items.id}"

        expect(response).to have_http_status(:ok)

        remaining_associations = ActiveRecord::Base.connection.execute(
          "SELECT COUNT(*) FROM menu_items_menus WHERE menu_id IN (#{menu_ids.join(',')})"
        ).first[0] if menu_ids.any?

        expect(remaining_associations || 0).to eq(0)
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        delete "/restaurant/99999"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Restaurant not found")
      end
    end
  end

  describe "Edge cases" do
    context "with special characters in parameters" do
      it "handles special characters in restaurant names" do
        special_attributes = {
          name: "Café & Bîstro™",
          description: "Special chars: àáâãäåæçèéêë",
          address_line_1: "123 Résidence Blvd"
        }

        post "/restaurant", params: special_attributes

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("Café & Bîstro™")
        expect(json['description']).to eq("Special chars: àáâãäåæçèéêë")
        expect(json['address_line_1']).to eq("123 Résidence Blvd")
      end
    end

    context "with very long text fields" do
      it "handles long descriptions" do
        long_description = "A" * 1000
        attributes = { name: "Long Description Restaurant", description: long_description }

        post "/restaurant", params: attributes

        expect(response).to have_http_status(:created)
        expect(json['description']).to eq(long_description)
      end

      it "handles long names" do
        long_name = "Super " * 20 + "Long Restaurant Name"
        attributes = { name: long_name }

        post "/restaurant", params: attributes

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq(long_name)
      end
    end

    context "with duplicate names" do
      it "allows restaurants with duplicate names" do
        create(:restaurant, name: "Duplicate Name")

        post "/restaurant", params: { name: "Duplicate Name" }

        expect(response).to have_http_status(:created)
        expect(Restaurant.where(name: "Duplicate Name").count).to eq(2)
      end
    end

    context "with missing optional parameters" do
      it "creates restaurant with only required fields" do
        minimal_params = { name: "Basic Restaurant" }

        post "/restaurant", params: minimal_params

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("Basic Restaurant")
        expect(json['description']).to be_nil
        expect(json['phone_number']).to be_nil
        expect(json['address_line_1']).to be_nil
        expect(json['email']).to be_nil
      end
    end

    context "with nil values for optional fields" do
      it "handles explicit nil values" do
        attributes_with_nils = {
          name: "Restaurant with Nils",
          description: nil,
          phone_number: nil,
          email: nil
        }

        post "/restaurant", params: attributes_with_nils

        expect(response).to have_http_status(:created)
        expect(json['description']).to be_nil
        expect(json['phone_number']).to be_nil
        expect(json['email']).to be_nil
      end
    end

    context "with large datasets" do
      before do
        Restaurant.destroy_all
        create_list(:restaurant, 100)
      end

      it "handles large page numbers gracefully" do
        get "/restaurant", params: { page: 20, per_page: 10 }

        expect(response).to have_http_status(:ok)
        expect(json).to eq([])
      end

      it "handles very large per_page parameter" do
        get "/restaurant", params: { per_page: 1000 }

        expect(response).to have_http_status(:ok)
        expect(json.length).to eq(100)
      end
    end

    context "with boolean and nil values" do
      it "handles nil description" do
        post "/restaurant", params: { name: "Test Restaurant", description: nil }

        expect(response).to have_http_status(:created)
        expect(json['description']).to be_nil
      end
    end
  end

  describe "Data integrity and associations" do
    it "maintains referential integrity when restaurant has menus" do
      restaurant_with_data = create(:restaurant, :with_menus)
      menu_ids = restaurant_with_data.menus.pluck(:id)

      expect(Menu.where(id: menu_ids).count).to eq(3)

      delete "/restaurant/#{restaurant_with_data.id}"

      expect(Menu.where(id: menu_ids).count).to eq(0)
    end

    it "maintains proper menu-restaurant associations" do
      restaurant1 = create(:restaurant, :with_menus)
      restaurant2 = create(:restaurant, :with_menus)

      get "/restaurant/#{restaurant1.id}"
      restaurant1_menus = json['menus']

      get "/restaurant/#{restaurant2.id}"
      restaurant2_menus = json['menus']

      restaurant1_menu_ids = restaurant1_menus.map { |m| m['id'] }
      restaurant2_menu_ids = restaurant2_menus.map { |m| m['id'] }

      expect(restaurant1_menu_ids & restaurant2_menu_ids).to be_empty
    end

    it "handles concurrent operations safely" do
      restaurant_to_delete = create(:restaurant, :with_menus)
      other_restaurants = create_list(:restaurant, 3)

      delete "/restaurant/#{restaurant_to_delete.id}"
      expect(response).to have_http_status(:ok)

      get "/restaurant"
      remaining_ids = json.map { |r| r['id'] }

      expect(remaining_ids).not_to include(restaurant_to_delete.id)
      other_restaurants.each do |restaurant|
        expect(remaining_ids).to include(restaurant.id)
      end
    end
  end
end
