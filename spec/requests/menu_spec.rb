require 'rails_helper'

RSpec.describe "Menus", type: :request do
  let(:restaurant) { create(:restaurant) }
  let(:menu) { create(:menu, restaurant: restaurant) }

  describe "GET /restaurant/:restaurant_id/menu" do
    context "when restaurant exists" do
      context "when restaurant has menus" do
        let!(:menus) { create_list(:menu, 5, restaurant: restaurant) }

        it "returns all menus for the restaurant" do
          get "/restaurant/#{restaurant.id}/menu"

          expect(response).to have_http_status(:ok)
          expect(json).to be_an(Array)
          expect(json.length).to eq(5)
          expect(json.map { |m| m['restaurant_id'] }).to all(eq(restaurant.id))
        end

        it "includes menu_items in the response" do
          menu_with_items = create(:menu, :with_menu_items, restaurant: restaurant)

          get "/restaurant/#{restaurant.id}/menu"

          menu_response = json.find { |m| m['id'] == menu_with_items.id }
          expect(menu_response).to have_key('menu_items')
          expect(menu_response['menu_items']).to be_an(Array)
          expect(menu_response['menu_items'].length).to eq(2)
        end

        it "orders menus by created_at desc" do
          Menu.where(restaurant: restaurant).destroy_all

          oldest_menu = create(:menu, restaurant: restaurant, created_at: 2.days.ago)
          newest_menu = create(:menu, restaurant: restaurant, created_at: 1.day.ago)

          get "/restaurant/#{restaurant.id}/menu"

          expect(json.length).to eq(2)
          expect(json.first['id']).to eq(newest_menu.id)
          expect(json.last['id']).to eq(oldest_menu.id)
        end

        context "with pagination" do
          before do
            Menu.where(restaurant: restaurant).destroy_all
            create_list(:menu, 15, restaurant: restaurant)
          end

          it "supports pagination with page parameter" do
            get "/restaurant/#{restaurant.id}/menu", params: { page: 2, per_page: 5 }

            expect(response).to have_http_status(:ok)
            expect(json.length).to eq(5)
          end

          it "supports custom per_page parameter" do
            get "/restaurant/#{restaurant.id}/menu", params: { per_page: 3 }

            expect(response).to have_http_status(:ok)
            expect(json.length).to eq(3)
          end

          it "defaults to page 1 and per_page 10" do
            get "/restaurant/#{restaurant.id}/menu"

            expect(response).to have_http_status(:ok)
            expect(json.length).to eq(10)
          end

          it "handles page parameter with per_page" do
            get "/restaurant/#{restaurant.id}/menu", params: { page: 2, per_page: 8 }

            expect(response).to have_http_status(:ok)
            expect(json.length).to eq(7)
          end

          it "handles invalid page parameter gracefully" do
            get "/restaurant/#{restaurant.id}/menu", params: { page: 0 }

            expect(response).to have_http_status(:ok)
            expect(json.length).to eq(10)
          end
        end
      end

      context "when restaurant has no menus" do
        it "returns an empty array" do
          get "/restaurant/#{restaurant.id}/menu"

          expect(response).to have_http_status(:ok)
          expect(json).to eq([])
        end
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        get "/restaurant/99999/menu"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Restaurant not found")
      end
    end
  end

  describe "GET /restaurant/:restaurant_id/menu/:id" do
    context "when menu exists and belongs to restaurant" do
      let(:menu) { create(:menu, :with_menu_items, restaurant: restaurant) }

      it "returns the menu with its items" do
        get "/restaurant/#{restaurant.id}/menu/#{menu.id}"

        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(menu.id)
        expect(json['name']).to eq(menu.name)
        expect(json['description']).to eq(menu.description)
        expect(json['category']).to eq(menu.category)
        expect(json['active']).to eq(menu.active)
        expect(json['restaurant_id']).to eq(restaurant.id)
        expect(json['menu_items']).to be_an(Array)
        expect(json['menu_items'].length).to eq(2)
      end

      it "includes all menu item attributes" do
        menu_item = menu.menu_items.first

        get "/restaurant/#{restaurant.id}/menu/#{menu.id}"

        item_response = json['menu_items'].find { |item| item['id'] == menu_item.id }
        expect(item_response['name']).to eq(menu_item.name)
        expect(item_response['price']).to eq(menu_item.price.to_s)
        expect(item_response['currency']).to eq(menu_item.currency)
        expect(item_response['description']).to eq(menu_item.description)
        expect(item_response['category']).to eq(menu_item.category)
        expect(item_response['available']).to eq(menu_item.available)
      end

      context "with time fields" do
        let(:menu_with_times) { create(:menu, :dinner, restaurant: restaurant) }

        it "includes time fields" do
          get "/restaurant/#{restaurant.id}/menu/#{menu_with_times.id}"

          expect(json['starts_at']).to eq(17)
          expect(json['ends_at']).to eq(22)
        end
      end

      context "without time fields" do
        let(:menu_without_times) { create(:menu, :without_times, restaurant: restaurant) }

        it "handles nil time fields" do
          get "/restaurant/#{restaurant.id}/menu/#{menu_without_times.id}"

          expect(json['starts_at']).to be_nil
          expect(json['ends_at']).to be_nil
        end
      end
    end

    context "when menu does not exist" do
      it "returns not found error" do
        get "/restaurant/#{restaurant.id}/menu/99999"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        get "/restaurant/99999/menu/#{menu.id}"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end

    context "when menu belongs to different restaurant" do
      let(:other_restaurant) { create(:restaurant) }
      let(:other_menu) { create(:menu, restaurant: other_restaurant) }

      it "returns not found error" do
        get "/restaurant/#{restaurant.id}/menu/#{other_menu.id}"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end
  end

  describe "POST /restaurant/:restaurant_id/menu" do
    let(:valid_attributes) do
      {
        name: "Breakfast Menu",
        description: "Fresh morning delights",
        category: "breakfast",
        active: true,
        starts_at: 6,
        ends_at: 11
      }
    end

    context "when restaurant exists" do
      context "with valid parameters" do
                it "creates a new menu" do
          expect {
            post "/restaurant/#{restaurant.id}/menu", params: valid_attributes
          }.to change(Menu, :count).by(1)

          expect(response).to have_http_status(:created)
          expect(json['name']).to eq("Breakfast Menu")
          expect(json['description']).to eq("Fresh morning delights")
          expect(json['category']).to eq("breakfast")
          expect(json['active']).to eq(true)
          expect(json['starts_at']).to eq(6)
          expect(json['ends_at']).to eq(11)
          expect(json['restaurant_id']).to eq(restaurant.id)
        end

        it "returns the created menu with menu_items array" do
          post "/restaurant/#{restaurant.id}/menu", params: valid_attributes

          expect(json).to have_key('menu_items')
          expect(json['menu_items']).to eq([])
        end

        it "handles menu creation without time fields" do
          params_without_times = valid_attributes.except(:starts_at, :ends_at)

          post "/restaurant/#{restaurant.id}/menu", params: params_without_times

          expect(response).to have_http_status(:created)
          expect(json['starts_at']).to be_nil
          expect(json['ends_at']).to be_nil
        end

        it "handles edge case hours correctly" do
          edge_case_attributes = valid_attributes.merge(starts_at: 0, ends_at: 23)

          post "/restaurant/#{restaurant.id}/menu", params: edge_case_attributes

          expect(response).to have_http_status(:created)
          expect(json['starts_at']).to eq(0)
          expect(json['ends_at']).to eq(23)
        end
      end

      context "with invalid parameters" do
        it "returns validation errors when name is missing" do
          invalid_attributes = valid_attributes.except(:name)

          post "/restaurant/#{restaurant.id}/menu", params: invalid_attributes

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['errors']).to include("Name can't be blank")
        end

        it "returns validation errors for invalid time range" do
          invalid_attributes = valid_attributes.merge(starts_at: 25, ends_at: -1)

          post "/restaurant/#{restaurant.id}/menu", params: invalid_attributes

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['errors']).to include("Starts at must be a valid hour (0-23)")
          expect(json['errors']).to include("Ends at must be a valid hour (0-23)")
        end

        it "validates start time must be before end time" do
          invalid_attributes = valid_attributes.merge(starts_at: 15, ends_at: 10)

          post "/restaurant/#{restaurant.id}/menu", params: invalid_attributes

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['errors']).to include("Start time must be before end time")
        end

        it "validates time fields when only one is provided" do
          invalid_attributes = valid_attributes.merge(starts_at: 10, ends_at: nil)

          post "/restaurant/#{restaurant.id}/menu", params: invalid_attributes

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['errors']).to include("Ends at can't be blank")
        end

        it "allows both time fields to be nil" do
          valid_attributes_no_times = valid_attributes.merge(starts_at: nil, ends_at: nil)

          post "/restaurant/#{restaurant.id}/menu", params: valid_attributes_no_times

          expect(response).to have_http_status(:created)
        end
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        post "/restaurant/99999/menu", params: valid_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Restaurant not found")
      end
    end
  end

  describe "PATCH /restaurant/:restaurant_id/menu/:id" do
    let(:update_attributes) do
      {
        name: "Updated Menu Name",
        description: "Updated description",
        active: false
      }
    end

    context "when menu exists and belongs to restaurant" do
      it "updates the menu" do
        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}", params: update_attributes

        expect(response).to have_http_status(:ok)
        expect(json['name']).to eq("Updated Menu Name")
        expect(json['description']).to eq("Updated description")
        expect(json['active']).to eq(false)
      end

      it "updates only provided attributes" do
        original_category = menu.category
        partial_update = { name: "New Name Only" }

        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}", params: partial_update

        expect(response).to have_http_status(:ok)
        expect(json['name']).to eq("New Name Only")
        expect(json['category']).to eq(original_category)
      end

      it "validates updated attributes" do
        invalid_update = { name: "", starts_at: 25 }

        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}", params: invalid_update

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name can't be blank")
        expect(json['errors']).to include("Starts at must be a valid hour (0-23)")
      end

      it "can update time fields" do
        time_update = { starts_at: 18, ends_at: 23 }

        patch "/restaurant/#{restaurant.id}/menu/#{menu.id}", params: time_update

        expect(response).to have_http_status(:ok)
        expect(json['starts_at']).to eq(18)
        expect(json['ends_at']).to eq(23)
      end

      it "can clear time fields" do
        menu_with_times = create(:menu, restaurant: restaurant, starts_at: 10, ends_at: 15)
        time_update = { starts_at: nil, ends_at: nil }

        patch "/restaurant/#{restaurant.id}/menu/#{menu_with_times.id}", params: time_update

        expect(response).to have_http_status(:ok)
        expect(json['starts_at']).to be_nil
        expect(json['ends_at']).to be_nil
      end
    end

    context "when menu does not exist" do
      it "returns not found error" do
        patch "/restaurant/#{restaurant.id}/menu/99999", params: update_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        patch "/restaurant/99999/menu/#{menu.id}", params: update_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end

    context "when menu belongs to different restaurant" do
      let(:other_restaurant) { create(:restaurant) }
      let(:other_menu) { create(:menu, restaurant: other_restaurant) }

      it "returns not found error" do
        patch "/restaurant/#{restaurant.id}/menu/#{other_menu.id}", params: update_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end
  end

  describe "DELETE /restaurant/:restaurant_id/menu/:id" do
    context "when menu exists and belongs to restaurant" do
      let!(:menu_to_delete) { create(:menu, restaurant: restaurant) }

      it "deletes the menu" do
        expect {
          delete "/restaurant/#{restaurant.id}/menu/#{menu_to_delete.id}"
        }.to change(Menu, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(json['message']).to eq("Menu deleted successfully")
      end

      it "removes associated menu item relationships" do
        menu_to_delete_with_items = create(:menu, :with_menu_items, restaurant: restaurant)

        expect {
          delete "/restaurant/#{restaurant.id}/menu/#{menu_to_delete_with_items.id}"
        }.to change(Menu, :count).by(-1)

        remaining_associations = ActiveRecord::Base.connection.execute(
          "SELECT COUNT(*) FROM menu_items_menus WHERE menu_id = #{menu_to_delete_with_items.id}"
        ).first[0]

        expect(remaining_associations || 0).to eq(0)
        expect(MenuItem.count).to eq(2)
      end
    end

    context "when menu does not exist" do
      it "returns not found error" do
        delete "/restaurant/#{restaurant.id}/menu/99999"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end

    context "when restaurant does not exist" do
      it "returns not found error" do
        delete "/restaurant/99999/menu/#{menu.id}"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end

    context "when menu belongs to different restaurant" do
      let(:other_restaurant) { create(:restaurant) }
      let(:other_menu) { create(:menu, restaurant: other_restaurant) }

      it "returns not found error" do
        delete "/restaurant/#{restaurant.id}/menu/#{other_menu.id}"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end
  end

  describe "Edge cases" do
    context "with special characters in parameters" do
      it "handles special characters in menu names" do
        special_attributes = {
          name: "Café & Dîner Menu™",
          description: "Special characters: àáâãäåæçèéêë"
        }

        post "/restaurant/#{restaurant.id}/menu", params: special_attributes

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("Café & Dîner Menu™")
        expect(json['description']).to eq("Special characters: àáâãäåæçèéêë")
      end
    end

    context "with large datasets" do
      before do
        Menu.where(restaurant: restaurant).destroy_all
        create_list(:menu, 100, restaurant: restaurant)
      end

      it "handles large page numbers gracefully" do
        get "/restaurant/#{restaurant.id}/menu", params: { page: 20, per_page: 10 }

        expect(response).to have_http_status(:ok)
        expect(json).to eq([])
      end

      it "handles very large per_page parameter" do
        get "/restaurant/#{restaurant.id}/menu", params: { per_page: 1000 }

        expect(response).to have_http_status(:ok)
        expect(json.length).to eq(100)
      end
    end

    context "with boolean and nil values" do
      it "handles boolean active field correctly" do
        post "/restaurant/#{restaurant.id}/menu", params: { name: "Test Menu", active: false }

        expect(response).to have_http_status(:created)
        expect(json['active']).to eq(false)
      end

      it "handles nil description" do
        post "/restaurant/#{restaurant.id}/menu", params: { name: "Test Menu", description: nil }

        expect(response).to have_http_status(:created)
        expect(json['description']).to be_nil
      end
    end

    context "with menu isolation between restaurants" do
      let(:other_restaurant) { create(:restaurant) }

      it "ensures menus are scoped to their restaurant" do
        menu1 = create(:menu, restaurant: restaurant, name: "Restaurant 1 Menu")
        menu2 = create(:menu, restaurant: other_restaurant, name: "Restaurant 2 Menu")

        get "/restaurant/#{restaurant.id}/menu"
        restaurant1_menus = json

        get "/restaurant/#{other_restaurant.id}/menu"
        restaurant2_menus = json

        restaurant1_menu_ids = restaurant1_menus.map { |m| m['id'] }
        restaurant2_menu_ids = restaurant2_menus.map { |m| m['id'] }

        expect(restaurant1_menu_ids).to include(menu1.id)
        expect(restaurant1_menu_ids).not_to include(menu2.id)
        expect(restaurant2_menu_ids).to include(menu2.id)
        expect(restaurant2_menu_ids).not_to include(menu1.id)
      end
    end
  end
end
