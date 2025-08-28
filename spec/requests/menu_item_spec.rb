require 'rails_helper'

RSpec.describe "MenuItems", type: :request do
  let(:menu_item) { create(:menu_item) }

  describe "GET /menu_item" do
    context "when menu items exist" do
      let!(:menu_items) { create_list(:menu_item, 5) }

      it "returns all menu items" do
        get "/menu_item"

        expect(response).to have_http_status(:ok)
        expect(json).to be_an(Array)
        expect(json.length).to eq(5)
      end

      it "includes associated menus in the response" do
        menu_item_with_menus = create(:menu_item, :with_menu)

        get "/menu_item"

        menu_item_response = json.find { |item| item['id'] == menu_item_with_menus.id }
        expect(menu_item_response).to have_key('menus')
        expect(menu_item_response['menus']).to be_an(Array)
        expect(menu_item_response['menus'].length).to eq(1)
      end

      it "orders menu items by created_at desc" do
        MenuItem.destroy_all

        oldest_item = create(:menu_item, created_at: 2.days.ago)
        newest_item = create(:menu_item, created_at: 1.day.ago)

        get "/menu_item"

        expect(json.length).to eq(2)
        expect(json.first['id']).to eq(newest_item.id)
        expect(json.last['id']).to eq(oldest_item.id)
      end

      context "with pagination" do
        before do
          MenuItem.destroy_all
          create_list(:menu_item, 15)
        end

        it "supports pagination with page parameter" do
          get "/menu_item", params: { page: 2, per_page: 5 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(5)
        end

        it "supports custom per_page parameter" do
          get "/menu_item", params: { per_page: 3 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(3)
        end

        it "defaults to page 1 and per_page 10" do
          get "/menu_item"

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(10)
        end

        it "handles page parameter with per_page" do
          get "/menu_item", params: { page: 2, per_page: 8 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(7)
        end

        it "handles invalid page parameter gracefully" do
          get "/menu_item", params: { page: 0 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(10)
        end
      end
    end

    context "when no menu items exist" do
      it "returns an empty array" do
        get "/menu_item"

        expect(response).to have_http_status(:ok)
        expect(json).to eq([])
      end
    end
  end

  describe "GET /menu_item/:id" do
    context "when menu item exists" do
      it "returns the menu item" do
        get "/menu_item/#{menu_item.id}"

        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(menu_item.id)
        expect(json['name']).to eq(menu_item.name)
        expect(json['created_at']).to eq(menu_item.created_at.strftime("%Y-%m-%dT%H:%M:%S.%LZ"))
        expect(json['updated_at']).to eq(menu_item.updated_at.strftime("%Y-%m-%dT%H:%M:%S.%LZ"))
      end

      it "includes associated menus" do
        menu_item_with_menus = create(:menu_item, :with_menu)

        get "/menu_item/#{menu_item_with_menus.id}"

        expect(json).to have_key('menus')
        expect(json['menus']).to be_an(Array)
        expect(json['menus'].length).to eq(1)

        menu_response = json['menus'].first
        expect(menu_response).to have_key('id')
        expect(menu_response).to have_key('name')
        expect(menu_response).to have_key('restaurant_id')
      end

      it "returns menu item with minimal data" do
        simple_menu_item = create(:menu_item)

        get "/menu_item/#{simple_menu_item.id}"

        expect(response).to have_http_status(:ok)
        expect(json['name']).to eq(simple_menu_item.name)
        expect(json).to have_key('menus')
        expect(json['menus']).to eq([])
      end

      it "returns all menu item attributes" do
        get "/menu_item/#{menu_item.id}"

        expect(json).to have_key('id')
        expect(json).to have_key('name')
        expect(json).to have_key('menus')
        expect(json).to have_key('created_at')
        expect(json).to have_key('updated_at')
      end
    end

    context "when menu item does not exist" do
      it "returns not found error" do
        get "/menu_item/99999"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end
  end

  describe "POST /menu_item" do
    let(:valid_attributes) do
      {
        menu_item: {
          name: "Grilled Salmon"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new menu item" do
        expect {
          post "/menu_item", params: valid_attributes
        }.to change(MenuItem, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("Grilled Salmon")
      end

      it "returns the created menu item" do
        post "/menu_item", params: valid_attributes

        expect(json['name']).to eq(valid_attributes[:menu_item][:name])
        expect(json).to have_key('id')
        expect(json).to have_key('created_at')
        expect(json).to have_key('updated_at')
        expect(json).to have_key('menus')
        expect(json['menus']).to eq([])
      end

      it "creates menu item with unique name" do
        first_attributes = { menu_item: { name: "Unique Dish" } }
        post "/menu_item", params: first_attributes
        expect(response).to have_http_status(:created)

        duplicate_attributes = { menu_item: { name: "Unique Dish" } }
        post "/menu_item", params: duplicate_attributes
        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name has already been taken")
      end
    end

    context "with invalid parameters" do
      it "returns validation errors when name is missing" do
        invalid_attributes = { menu_item: {} }

        post "/menu_item", params: invalid_attributes

        expect(response).to have_http_status(:bad_request)
        expect(json['error']).to eq("Missing required parameter: menu_item")
      end

      it "returns validation errors when name is empty" do
        invalid_attributes = { menu_item: { name: "" } }

        post "/menu_item", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name can't be blank")
      end

      it "returns missing parameter error when menu_item key is missing" do
        invalid_attributes = { name: "Test Item" }

        post "/menu_item", params: invalid_attributes

        expect(response).to have_http_status(:bad_request)
        expect(json['error']).to eq("Missing required parameter: menu_item")
      end

      it "returns validation errors for duplicate names" do
        create(:menu_item, name: "Duplicate Item")
        duplicate_attributes = { menu_item: { name: "Duplicate Item" } }

        post "/menu_item", params: duplicate_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name has already been taken")
      end
    end
  end

  describe "PATCH /menu_item/:id" do
    let(:update_attributes) do
      {
        menu_item: {
          name: "Updated Menu Item Name"
        }
      }
    end

    context "when menu item exists" do
      it "updates the menu item" do
        patch "/menu_item/#{menu_item.id}", params: update_attributes

        expect(response).to have_http_status(:ok)
        expect(json['name']).to eq("Updated Menu Item Name")
      end

      it "returns the updated menu item" do
        original_id = menu_item.id
        patch "/menu_item/#{menu_item.id}", params: update_attributes

        expect(json['id']).to eq(original_id)
        expect(json['name']).to eq("Updated Menu Item Name")
        expect(json).to have_key('updated_at')
        expect(json).to have_key('menus')
      end

      it "validates updated attributes" do
        invalid_update = { menu_item: { name: "" } }

        patch "/menu_item/#{menu_item.id}", params: invalid_update

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name can't be blank")
      end

      it "validates name uniqueness on update" do
        existing_item = create(:menu_item, name: "Existing Item")
        duplicate_update = { menu_item: { name: "Existing Item" } }

        patch "/menu_item/#{menu_item.id}", params: duplicate_update

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name has already been taken")
      end

      it "handles missing parameter error" do
        invalid_attributes = { name: "Test Update" }

        patch "/menu_item/#{menu_item.id}", params: invalid_attributes

        expect(response).to have_http_status(:bad_request)
        expect(json['error']).to eq("Missing required parameter: menu_item")
      end

      it "preserves associated menus" do
        menu_item_with_menus = create(:menu_item, :with_menu)
        original_menu_count = menu_item_with_menus.menus.count

        patch "/menu_item/#{menu_item_with_menus.id}", params: { menu_item: { name: "Updated Name" } }

        expect(response).to have_http_status(:ok)
        menu_item_with_menus.reload
        expect(menu_item_with_menus.menus.count).to eq(original_menu_count)
      end
    end

    context "when menu item does not exist" do
      it "returns not found error" do
        patch "/menu_item/99999", params: update_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end
  end

  describe "DELETE /menu_item/:id" do
    context "when menu item exists" do
      let!(:menu_item_to_delete) { create(:menu_item) }

      it "deletes the menu item" do
        expect {
          delete "/menu_item/#{menu_item_to_delete.id}"
        }.to change(MenuItem, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(json['message']).to eq("Menu item deleted successfully")
      end

      it "deletes associated menu_menu_item records (cascade delete)" do
        menu_item_with_associations = create(:menu_item, :with_menu)
        menu_menu_item_count = MenuMenuItem.where(menu_item: menu_item_with_associations).count

        expect(menu_menu_item_count).to be > 0

        expect {
          delete "/menu_item/#{menu_item_with_associations.id}"
        }.to change(MenuMenuItem, :count).by(-menu_menu_item_count)

        expect(response).to have_http_status(:ok)
      end

      it "does not affect other menu items" do
        other_menu_item = create(:menu_item)

        delete "/menu_item/#{menu_item_to_delete.id}"

        expect(response).to have_http_status(:ok)
        expect(MenuItem.find_by(id: other_menu_item.id)).to be_present
      end
    end

    context "when menu item does not exist" do
      it "returns not found error" do
        delete "/menu_item/99999"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu item not found")
      end
    end
  end

  describe "Edge cases" do
    context "with special characters in parameters" do
      it "handles special characters in menu item names" do
        special_attributes = {
          menu_item: {
            name: "Café au Lait & Crème Brûlée™"
          }
        }

        post "/menu_item", params: special_attributes

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("Café au Lait & Crème Brûlée™")
      end
    end

    context "with very long text fields" do
      it "handles very long names" do
        long_name = "Super " * 20 + "Long Menu Item Name"
        long_name_attributes = {
          menu_item: {
            name: long_name
          }
        }

        post "/menu_item", params: long_name_attributes

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq(long_name)
      end
    end

    context "with large datasets" do
      before do
        MenuItem.destroy_all
        create_list(:menu_item, 100)
      end

      it "handles large page numbers gracefully" do
        get "/menu_item", params: { page: 20, per_page: 10 }

        expect(response).to have_http_status(:ok)
        expect(json).to eq([])
      end

      it "handles very large per_page parameter" do
        get "/menu_item", params: { per_page: 1000 }

        expect(response).to have_http_status(:ok)
        expect(json.length).to eq(100)
      end
    end

    context "with name uniqueness" do
      it "enforces unique names across all menu items" do
        create(:menu_item, name: "Unique Item")

        duplicate_attributes = { menu_item: { name: "Unique Item" } }

        post "/menu_item", params: duplicate_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name has already been taken")
      end
    end
  end

  describe "Data consistency and associations" do
    it "maintains menu associations correctly after creation" do
      menu_item_with_menu = create(:menu_item, :with_menu)

      get "/menu_item/#{menu_item_with_menu.id}"

      expect(json['menus']).to be_an(Array)
      expect(json['menus'].length).to eq(1)
      expect(json['menus'].first).to have_key('id')
      expect(json['menus'].first).to have_key('name')
      expect(json['menus'].first).to have_key('restaurant_id')
    end

    it "handles multiple menu associations" do
      menu_item = create(:menu_item)
      menu1 = create(:menu)
      menu2 = create(:menu)

      create(:menu_menu_item, menu: menu1, menu_item: menu_item)
      create(:menu_menu_item, menu: menu2, menu_item: menu_item)

      get "/menu_item/#{menu_item.id}"

      expect(json['menus']).to be_an(Array)
      expect(json['menus'].length).to eq(2)
    end

    it "handles concurrent operations safely" do
      menu_item_to_delete = create(:menu_item)
      other_items = create_list(:menu_item, 3)

      delete "/menu_item/#{menu_item_to_delete.id}"
      expect(response).to have_http_status(:ok)

      get "/menu_item"
      remaining_ids = json.map { |item| item['id'] }

      expect(remaining_ids).not_to include(menu_item_to_delete.id)
      other_items.each do |item|
        expect(remaining_ids).to include(item.id)
      end
    end

    it "properly includes menu items on multiple menus" do
      menu_item = create(:menu_item, name: "Shared Item")
      restaurant1 = create(:restaurant)
      restaurant2 = create(:restaurant)
      menu1 = create(:menu, restaurant: restaurant1)
      menu2 = create(:menu, restaurant: restaurant2)

      create(:menu_menu_item, menu: menu1, menu_item: menu_item)
      create(:menu_menu_item, menu: menu2, menu_item: menu_item)

      get "/menu_item/#{menu_item.id}"

      expect(json['menus'].length).to eq(2)
      menu_ids = json['menus'].map { |m| m['id'] }
      expect(menu_ids).to include(menu1.id, menu2.id)
    end
  end
end
