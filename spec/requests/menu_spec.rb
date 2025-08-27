require 'rails_helper'

RSpec.describe "Menus", type: :request do
  let(:menu) { create(:menu) }

  describe "GET /menu" do
    context "when menus exist" do
      let!(:menus) { create_list(:menu, 5) }

      it "returns all menus" do
        get "/menu"

        expect(response).to have_http_status(:ok)
        expect(json).to be_an(Array)
        expect(json.length).to eq(5)
      end

      it "includes menu_items in the response" do
        menu_with_items = menus.first
        create_list(:menu_item, 2, menu: menu_with_items)

        get "/menu"

        menu_response = json.find { |m| m['id'] == menu_with_items.id }
        expect(menu_response).to have_key('menu_items')
        expect(menu_response['menu_items']).to be_an(Array)
        expect(menu_response['menu_items'].length).to eq(2)
      end

      it "orders menus by created_at desc" do
        Menu.destroy_all

        oldest_menu = create(:menu, created_at: 2.days.ago)
        newest_menu = create(:menu, created_at: 1.day.ago)

        get "/menu"

        expect(json.length).to eq(2)
        expect(json.first['id']).to eq(newest_menu.id)
        expect(json.last['id']).to eq(oldest_menu.id)
      end

      context "with pagination" do
        before do
          Menu.destroy_all
          create_list(:menu, 15)
        end

        it "supports pagination with page parameter" do
          get "/menu", params: { page: 2, per_page: 5 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(5)
        end

        it "supports custom per_page parameter" do
          get "/menu", params: { per_page: 3 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(3)
        end

        it "defaults to page 1 and per_page 10" do
          get "/menu"

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(10)
        end

        it "handles page parameter with per_page" do
          get "/menu", params: { page: 2, per_page: 8 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(7)
        end

        it "handles invalid page parameter gracefully" do
          get "/menu", params: { page: 0 }

          expect(response).to have_http_status(:ok)
          expect(json.length).to eq(10)
        end
      end
    end

    context "when no menus exist" do
      it "returns an empty array" do
        get "/menu"

        expect(response).to have_http_status(:ok)
        expect(json).to eq([])
      end
    end
  end

  describe "GET /menu/:id" do
    context "when menu exists" do
      let!(:menu_items) { create_list(:menu_item, 3, menu: menu) }

      it "returns the menu with its items" do
        get "/menu/#{menu.id}"

        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(menu.id)
        expect(json['name']).to eq(menu.name)
        expect(json['description']).to eq(menu.description)
        expect(json['category']).to eq(menu.category)
        expect(json['active']).to eq(menu.active)
        expect(json['menu_items']).to be_an(Array)
        expect(json['menu_items'].length).to eq(3)
      end

      it "includes all menu item attributes" do
        menu_item = menu_items.first

        get "/menu/#{menu.id}"

        item_response = json['menu_items'].find { |item| item['id'] == menu_item.id }
        expect(item_response['name']).to eq(menu_item.name)
        expect(item_response['price']).to eq(menu_item.price.to_s)
        expect(item_response['currency']).to eq(menu_item.currency)
        expect(item_response['description']).to eq(menu_item.description)
        expect(item_response['category']).to eq(menu_item.category)
        expect(item_response['available']).to eq(menu_item.available)
      end

      context "with time fields" do
        let(:menu_with_times) { create(:menu, :dinner) }

        it "includes time fields" do
          get "/menu/#{menu_with_times.id}"

          expect(json['starts_at']).to eq(17)
          expect(json['ends_at']).to eq(22)
        end
      end

      context "without time fields" do
        let(:menu_without_times) { create(:menu, :without_times) }

        it "handles nil time fields" do
          get "/menu/#{menu_without_times.id}"

          expect(json['starts_at']).to be_nil
          expect(json['ends_at']).to be_nil
        end
      end
    end

    context "when menu does not exist" do
      it "returns not found error" do
        get "/menu/99999"

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end
  end

  describe "POST /menu" do
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

    context "with valid parameters" do
      it "creates a new menu" do
        expect {
          post "/menu", params: valid_attributes
        }.to change(Menu, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("Breakfast Menu")
        expect(json['description']).to eq("Fresh morning delights")
        expect(json['category']).to eq("breakfast")
        expect(json['active']).to eq(true)
        expect(json['starts_at']).to eq(6)
        expect(json['ends_at']).to eq(11)
      end

      it "returns the created menu with menu_items array" do
        post "/menu", params: valid_attributes

        expect(json).to have_key('menu_items')
        expect(json['menu_items']).to eq([])
      end

      it "handles menu creation without time fields" do
        params_without_times = valid_attributes.except(:starts_at, :ends_at)

        post "/menu", params: params_without_times

        expect(response).to have_http_status(:created)
        expect(json['starts_at']).to be_nil
        expect(json['ends_at']).to be_nil
      end

      it "handles edge case hours correctly" do
        edge_case_attributes = valid_attributes.merge(starts_at: 0, ends_at: 23)

        post "/menu", params: edge_case_attributes

        expect(response).to have_http_status(:created)
        expect(json['starts_at']).to eq(0)
        expect(json['ends_at']).to eq(23)
      end
    end

    context "with invalid parameters" do
      it "returns validation errors when name is missing" do
        invalid_attributes = valid_attributes.except(:name)

        post "/menu", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name can't be blank")
      end

      it "returns validation errors for invalid time range" do
        invalid_attributes = valid_attributes.merge(starts_at: 25, ends_at: -1)

        post "/menu", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Starts at must be a valid hour (0-23)")
        expect(json['errors']).to include("Ends at must be a valid hour (0-23)")
      end

      it "validates start time must be before end time" do
        invalid_attributes = valid_attributes.merge(starts_at: 15, ends_at: 10)

        post "/menu", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Start time must be before end time")
      end

      it "validates time fields when only one is provided" do
        invalid_attributes = valid_attributes.merge(starts_at: 10, ends_at: nil)

        post "/menu", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Ends at can't be blank")
      end

      it "allows both time fields to be nil" do
        valid_attributes_no_times = valid_attributes.merge(starts_at: nil, ends_at: nil)

        post "/menu", params: valid_attributes_no_times

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe "PATCH /menu/:id" do
    let(:update_attributes) do
      {
        name: "Updated Menu Name",
        description: "Updated description",
        active: false
      }
    end

    context "when menu exists" do
      it "updates the menu" do
        patch "/menu/#{menu.id}", params: update_attributes

        expect(response).to have_http_status(:ok)
        expect(json['name']).to eq("Updated Menu Name")
        expect(json['description']).to eq("Updated description")
        expect(json['active']).to eq(false)
      end

      it "updates only provided attributes" do
        original_category = menu.category
        partial_update = { name: "New Name Only" }

        patch "/menu/#{menu.id}", params: partial_update

        expect(response).to have_http_status(:ok)
        expect(json['name']).to eq("New Name Only")
        expect(json['category']).to eq(original_category)
      end

      it "validates updated attributes" do
        invalid_update = { name: "", starts_at: 25 }

        patch "/menu/#{menu.id}", params: invalid_update

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['errors']).to include("Name can't be blank")
        expect(json['errors']).to include("Starts at must be a valid hour (0-23)")
      end

      it "can update time fields" do
        time_update = { starts_at: 18, ends_at: 23 }

        patch "/menu/#{menu.id}", params: time_update

        expect(response).to have_http_status(:ok)
        expect(json['starts_at']).to eq(18)
        expect(json['ends_at']).to eq(23)
      end

      it "can clear time fields" do
        menu_with_times = create(:menu, starts_at: 10, ends_at: 15)
        time_update = { starts_at: nil, ends_at: nil }

        patch "/menu/#{menu_with_times.id}", params: time_update

        expect(response).to have_http_status(:ok)
        expect(json['starts_at']).to be_nil
        expect(json['ends_at']).to be_nil
      end
    end

    context "when menu does not exist" do
      it "returns not found error" do
        patch "/menu/99999", params: update_attributes

        expect(response).to have_http_status(:not_found)
        expect(json['error']).to eq("Menu not found")
      end
    end
  end

  describe "DELETE /menu/:id" do
    context "when menu exists" do
      let!(:menu_to_delete) { create(:menu) }

      it "deletes the menu" do
        expect {
          delete "/menu/#{menu_to_delete.id}"
        }.to change(Menu, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(json['message']).to eq("Menu deleted successfully")
      end

      it "deletes associated menu items" do
        create_list(:menu_item, 3, menu: menu_to_delete)

        expect {
          delete "/menu/#{menu_to_delete.id}"
        }.to change(MenuItem, :count).by(-3)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when menu does not exist" do
      it "returns not found error" do
        delete "/menu/99999"

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

        post "/menu", params: special_attributes

        expect(response).to have_http_status(:created)
        expect(json['name']).to eq("Café & Dîner Menu™")
        expect(json['description']).to eq("Special characters: àáâãäåæçèéêë")
      end
    end

    context "with large datasets" do
      before do
        Menu.destroy_all
        create_list(:menu, 100)
      end

      it "handles large page numbers gracefully" do
        get "/menu", params: { page: 20, per_page: 10 }

        expect(response).to have_http_status(:ok)
        expect(json).to eq([])
      end

      it "handles very large per_page parameter" do
        get "/menu", params: { per_page: 1000 }

        expect(response).to have_http_status(:ok)
        expect(json.length).to eq(100)
      end
    end

    context "with boolean and nil values" do
      it "handles boolean active field correctly" do
        post "/menu", params: { name: "Test Menu", active: false }

        expect(response).to have_http_status(:created)
        expect(json['active']).to eq(false)
      end

      it "handles nil description" do
        post "/menu", params: { name: "Test Menu", description: nil }

        expect(response).to have_http_status(:created)
        expect(json['description']).to be_nil
      end
    end

    context "with concurrent operations" do
      it "handles deletion of menu with associated items" do
        menu_with_items = create(:menu)
        create_list(:menu_item, 5, menu: menu_with_items)

        expect {
          delete "/menu/#{menu_with_items.id}"
        }.to change(Menu, :count).by(-1)
         .and change(MenuItem, :count).by(-5)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
