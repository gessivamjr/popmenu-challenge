require 'rails_helper'

RSpec.describe Restaurants::ImportService do
  let(:restaurant_import_id) { 123 }

  before do
    allow(RestaurantImportLogger).to receive(:info)
    allow(RestaurantImportLogger).to receive(:error)
  end

  describe ".call" do
    it "creates a new instance and calls #call" do
      json_data = { "restaurants" => [] }
      service_instance = instance_double(described_class)

      expect(described_class).to receive(:new).with(json_data, restaurant_import_id).and_return(service_instance)
      expect(service_instance).to receive(:call)

      described_class.call(json: json_data, restaurant_import_id: restaurant_import_id)
    end
  end

  describe "#call" do
    let(:service) { described_class.new(json_data, restaurant_import_id) }

    context "with valid restaurant data" do
      let(:json_data) do
        {
          "restaurants" => [
            {
              "name" => "Test Restaurant",
              "menus" => [
                {
                  "name" => "Lunch Menu",
                  "menu_items" => [
                    { "name" => "Burger", "price" => 12.99 },
                    { "name" => "Fries", "price" => 4.99 }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "processes restaurants successfully" do
        result = service.call

        expect(result[:created_restaurants_count]).to eq(1)
        expect(result[:created_menus_count]).to eq(1)
        expect(result[:created_menu_items_count]).to eq(2)
        expect(result[:linked_menu_items_count]).to eq(2)
        expect(result[:failed_restaurants_count]).to eq(0)
        expect(result[:failed_menus_count]).to eq(0)
        expect(result[:failed_menu_items_count]).to eq(0)
        expect(result[:failed_links_count]).to eq(0)
      end

      it "creates restaurant, menu and menu items in database" do
        expect {
          service.call
        }.to change(Restaurant, :count).by(1)
          .and change(Menu, :count).by(1)
          .and change(MenuItem, :count).by(2)
          .and change(MenuMenuItem, :count).by(2)

        restaurant = Restaurant.find_by(name: "Test Restaurant")
        menu = restaurant.menus.find_by(name: "Lunch Menu")
        burger = MenuItem.find_by(name: "Burger")
        fries = MenuItem.find_by(name: "Fries")

        expect(menu.menu_menu_items.count).to eq(2)
        expect(menu.menu_items).to include(burger, fries)
      end

      it "logs successful operations" do
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Created Restaurant=Test Restaurant")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Created Menu=Lunch Menu for Restaurant=Test Restaurant")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Created MenuItem=Burger")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Created MenuItem=Fries")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Added MenuItem=Burger to Menu=Lunch Menu")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Added MenuItem=Fries to Menu=Lunch Menu")

        service.call
      end
    end

    context "with existing restaurants and menus" do
      let!(:existing_restaurant) { create(:restaurant, name: "Existing Restaurant") }
      let!(:existing_menu) { create(:menu, name: "Existing Menu", restaurant: existing_restaurant) }
      let!(:existing_menu_item) { create(:menu_item, name: "Existing Item") }

      let(:json_data) do
        {
          "restaurants" => [
            {
              "name" => "Existing Restaurant",
              "menus" => [
                {
                  "name" => "Existing Menu",
                  "menu_items" => [
                    { "name" => "Existing Item", "price" => 10.00 },
                    { "name" => "New Item", "price" => 15.00 }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "finds existing records and creates new ones" do
        result = service.call

        expect(result[:created_restaurants_count]).to eq(0)
        expect(result[:created_menus_count]).to eq(0)
        expect(result[:created_menu_items_count]).to eq(1)
        expect(result[:linked_menu_items_count]).to eq(2)
      end

      it "logs found existing records" do
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Found Restaurant=Existing Restaurant")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Found Menu=Existing Menu for Restaurant=Existing Restaurant")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Found MenuItem=Existing Item")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Created MenuItem=New Item")

        service.call
      end

      it "doesn't create duplicate menu item links" do
        create(:menu_menu_item, menu: existing_menu, menu_item: existing_menu_item, price: 5.00)

        expect {
          service.call
        }.to change(MenuMenuItem, :count).by(1)

        result = service.call
        expect(result[:linked_menu_items_count]).to eq(1)
      end
    end

    context "with dishes instead of menu_items" do
      let(:json_data) do
        {
          "restaurants" => [
            {
              "name" => "Restaurant with Dishes",
              "menus" => [
                {
                  "name" => "Dinner Menu",
                  "dishes" => [
                    { "name" => "Steak", "price" => 25.99 },
                    { "name" => "Chicken", "price" => 18.99 }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "processes dishes the same as menu_items" do
        result = service.call

        expect(result[:created_restaurants_count]).to eq(1)
        expect(result[:created_menus_count]).to eq(1)
        expect(result[:created_menu_items_count]).to eq(2)
        expect(result[:linked_menu_items_count]).to eq(2)

        restaurant = Restaurant.find_by(name: "Restaurant with Dishes")
        menu = restaurant.menus.find_by(name: "Dinner Menu")
        expect(menu.menu_items.pluck(:name)).to contain_exactly("Steak", "Chicken")
      end
    end

    context "with both menu_items and dishes" do
      let(:json_data) do
        {
          "restaurants" => [
            {
              "name" => "Mixed Restaurant",
              "menus" => [
                {
                  "name" => "Mixed Menu",
                  "menu_items" => [
                    { "name" => "Menu Item", "price" => 10.00 }
                  ],
                  "dishes" => [
                    { "name" => "Dish Item", "price" => 15.00 }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "prioritizes menu_items over dishes" do
        result = service.call

        expect(result[:created_menu_items_count]).to eq(1)
        expect(result[:linked_menu_items_count]).to eq(1)

        restaurant = Restaurant.find_by(name: "Mixed Restaurant")
        menu = restaurant.menus.first
        expect(menu.menu_items.pluck(:name)).to eq(["Menu Item"])
      end
    end

    context "with empty or missing data" do
      context "when restaurants array is empty" do
        let(:json_data) { { "restaurants" => [] } }

        it "returns zero counts" do
          result = service.call

          expect(result[:created_restaurants_count]).to eq(0)
          expect(result[:created_menus_count]).to eq(0)
          expect(result[:created_menu_items_count]).to eq(0)
          expect(result[:linked_menu_items_count]).to eq(0)
          expect(result[:failed_restaurants_count]).to eq(0)
          expect(result[:failed_menus_count]).to eq(0)
          expect(result[:failed_menu_items_count]).to eq(0)
          expect(result[:failed_links_count]).to eq(0)
        end
      end

      context "when restaurants key is missing" do
        let(:json_data) { {} }

        it "treats as empty array and returns zero counts" do
          result = service.call

          expect(result[:created_restaurants_count]).to eq(0)
          expect(result[:failed_restaurants_count]).to eq(0)
        end
      end

      context "when menus array is empty" do
        let(:json_data) do
          {
            "restaurants" => [
              { "name" => "Restaurant No Menus", "menus" => [] }
            ]
          }
        end

        it "creates restaurant but no menus" do
          result = service.call

          expect(result[:created_restaurants_count]).to eq(1)
          expect(result[:created_menus_count]).to eq(0)
          expect(result[:created_menu_items_count]).to eq(0)
        end
      end

      context "when menus key is missing" do
        let(:json_data) do
          {
            "restaurants" => [
              { "name" => "Restaurant No Menus Key" }
            ]
          }
        end

        it "creates restaurant but no menus" do
          result = service.call

          expect(result[:created_restaurants_count]).to eq(1)
          expect(result[:created_menus_count]).to eq(0)
        end
      end

      context "when menu_items and dishes are both empty" do
        let(:json_data) do
          {
            "restaurants" => [
              {
                "name" => "Restaurant",
                "menus" => [
                  { "name" => "Empty Menu", "menu_items" => [], "dishes" => [] }
                ]
              }
            ]
          }
        end

        it "creates restaurant and menu but no items" do
          result = service.call

          expect(result[:created_restaurants_count]).to eq(1)
          expect(result[:created_menus_count]).to eq(1)
          expect(result[:created_menu_items_count]).to eq(0)
          expect(result[:linked_menu_items_count]).to eq(0)
        end
      end
    end

    context "with restaurant creation errors" do
      let(:json_data) do
        {
          "restaurants" => [
            { "name" => nil },
            { "name" => "Valid Restaurant", "menus" => [] }
          ]
        }
      end

      before do
        allow(Restaurant).to receive(:find_or_create_by!).with(name: nil).and_raise(ActiveRecord::RecordInvalid.new(Restaurant.new))
        allow(Restaurant).to receive(:find_or_create_by!).with(name: "Valid Restaurant").and_call_original
      end

      it "handles restaurant creation errors and continues processing" do
        result = service.call

        expect(result[:created_restaurants_count]).to eq(1)
        expect(result[:failed_restaurants_count]).to eq(1)
        expect(result[:created_menus_count]).to eq(0)
      end

      it "logs restaurant creation errors" do
        expect(RestaurantImportLogger).to receive(:error).with(/Failed creating Restaurant name= exception=ActiveRecord::RecordInvalid/)

        service.call
      end
    end

    context "with menu creation errors" do
      let(:restaurant) { create(:restaurant, name: "Test Restaurant") }
      let(:json_data) do
        {
          "restaurants" => [
            {
              "name" => "Test Restaurant",
              "menus" => [
                { "name" => "Error Menu", "menu_items" => [] }
              ]
            }
          ]
        }
      end

      before do
        menus_relation = double("menus_relation")
        allow(restaurant).to receive(:menus).and_return(menus_relation)
        allow(menus_relation).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordInvalid.new(Menu.new))
        allow(Restaurant).to receive(:find_or_create_by!).with(name: "Test Restaurant").and_return(restaurant)
        allow(restaurant).to receive(:previously_new_record?).and_return(true)
        allow(restaurant).to receive(:name).and_return("Test Restaurant")
      end

      it "handles menu creation errors and continues processing" do
        result = service.call

        expect(result[:created_restaurants_count]).to eq(1)
        expect(result[:created_menus_count]).to eq(0)
        expect(result[:failed_menus_count]).to eq(1)
      end

      it "logs menu creation errors" do
        expect(RestaurantImportLogger).to receive(:error).with(/Failed creating Menu name=Error Menu for Restaurant=Test Restaurant/)

        service.call
      end
    end

    context "with menu item creation errors" do
      let(:json_data) do
        {
          "restaurants" => [
            {
              "name" => "Test Restaurant",
              "menus" => [
                {
                  "name" => "Test Menu",
                  "menu_items" => [
                    { "name" => nil, "price" => 10.00 },
                    { "name" => "Valid Item", "price" => 15.00 }
                  ]
                }
              ]
            }
          ]
        }
      end

      before do
        allow(MenuItem).to receive(:find_or_create_by!).with(name: nil).and_raise(ActiveRecord::RecordInvalid.new(MenuItem.new))
        allow(MenuItem).to receive(:find_or_create_by!).with(name: "Valid Item").and_call_original
      end

      it "handles menu item creation errors and continues processing" do
        result = service.call

        expect(result[:created_menu_items_count]).to eq(1)
        expect(result[:failed_menu_items_count]).to eq(1)
        expect(result[:linked_menu_items_count]).to eq(1)
        expect(result[:failed_links_count]).to eq(0)
      end

      it "logs menu item creation errors" do
        expect(RestaurantImportLogger).to receive(:error).with(/Failed creating MenuItem name= price=10.0 exception=ActiveRecord::RecordInvalid/)

        service.call
      end
    end

    context "with menu item linking errors" do
      let(:json_data) do
        {
          "restaurants" => [
            {
              "name" => "Test Restaurant",
              "menus" => [
                {
                  "name" => "Test Menu",
                  "menu_items" => [
                    { "name" => "Test Item", "price" => nil }
                  ]
                }
              ]
            }
          ]
        }
      end

      before do
        allow_any_instance_of(Menu).to receive(:add_menu_item).and_return({
          success: false,
          errors: [ "Price can't be blank" ]
        })
      end

      it "handles menu item linking errors" do
        result = service.call

        expect(result[:created_menu_items_count]).to eq(1)
        expect(result[:linked_menu_items_count]).to eq(0)
        expect(result[:failed_links_count]).to eq(1)
      end

      it "logs menu item linking errors" do
        expect(RestaurantImportLogger).to receive(:error).with(/Failed adding MenuItem=Test Item to Menu=Test Menu errors=Price can't be blank/)

        service.call
      end
    end

    context "with multiple restaurants and complex scenarios" do
      let(:json_data) do
        {
          "restaurants" => [
            {
              "name" => "Restaurant 1",
              "menus" => [
                {
                  "name" => "Breakfast",
                  "menu_items" => [
                    { "name" => "Pancakes", "price" => 8.99 },
                    { "name" => "Coffee", "price" => 2.99 }
                  ]
                },
                {
                  "name" => "Lunch",
                  "dishes" => [
                    { "name" => "Sandwich", "price" => 12.99 }
                  ]
                }
              ]
            },
            {
              "name" => "Restaurant 2",
              "menus" => [
                {
                  "name" => "Dinner",
                  "menu_items" => [
                    { "name" => "Steak", "price" => 29.99 },
                    { "name" => "Wine", "price" => 45.00 }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "processes multiple restaurants correctly" do
        result = service.call

        expect(result[:created_restaurants_count]).to eq(2)
        expect(result[:created_menus_count]).to eq(3)
        expect(result[:created_menu_items_count]).to eq(5)
        expect(result[:linked_menu_items_count]).to eq(5)

        restaurant1 = Restaurant.find_by(name: "Restaurant 1")
        restaurant2 = Restaurant.find_by(name: "Restaurant 2")

        expect(restaurant1.menus.count).to eq(2)
        expect(restaurant2.menus.count).to eq(1)

        breakfast_menu = restaurant1.menus.find_by(name: "Breakfast")
        expect(breakfast_menu.menu_items.pluck(:name)).to contain_exactly("Pancakes", "Coffee")
      end
    end

    context "with edge case data types" do
      let(:json_data) do
        {
          "restaurants" => [
            {
              "name" => "Edge Case Restaurant",
              "menus" => [
                {
                  "name" => "Edge Menu",
                  "menu_items" => [
                    { "name" => "Item with Float Price", "price" => 12.5 },
                    { "name" => "Item with String Price", "price" => "15.99" },
                    { "name" => "Item with Zero Price", "price" => 0 }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "handles different price data types" do
        result = service.call

        expect(result[:created_menu_items_count]).to eq(3)
        expect(result[:linked_menu_items_count]).to eq(3)
        expect(result[:failed_links_count]).to eq(0)

        menu = Menu.find_by(name: "Edge Menu")
        prices = menu.menu_menu_items.pluck(:price)

        expect(prices).to contain_exactly(12.5, 15.99, 0.0)
      end
    end

    describe "integration with actual models" do
      let(:json_data) do
        {
          "restaurants" => [
            {
              "name" => "Integration Test Restaurant",
              "menus" => [
                {
                  "name" => "Integration Menu",
                  "menu_items" => [
                    { "name" => "Integration Item", "price" => 19.99 }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "creates proper model relationships" do
        service.call

        restaurant = Restaurant.find_by(name: "Integration Test Restaurant")
        menu = restaurant.menus.find_by(name: "Integration Menu")
        menu_item = MenuItem.find_by(name: "Integration Item")
        menu_menu_item = MenuMenuItem.find_by(menu: menu, menu_item: menu_item)

        expect(restaurant).to be_present
        expect(menu).to be_present
        expect(menu_item).to be_present
        expect(menu_menu_item).to be_present
        expect(menu_menu_item.price).to eq(19.99)
      end

      it "respects model validations" do
        service.call

        restaurant = Restaurant.find_by(name: "Integration Test Restaurant")
        expect(restaurant).to be_valid

        menu = restaurant.menus.find_by(name: "Integration Menu")
        expect(menu).to be_valid

        menu_item = MenuItem.find_by(name: "Integration Item")
        expect(menu_item).to be_valid
      end
    end

    describe "logging behavior" do
      let(:json_data) do
        {
          "restaurants" => [
            {
              "name" => "Logging Test Restaurant",
              "menus" => [
                {
                  "name" => "Logging Menu",
                  "menu_items" => [
                    { "name" => "Logging Item", "price" => 10.00 }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "logs with consistent format including restaurant_import_id" do
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Created Restaurant=Logging Test Restaurant")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Created Menu=Logging Menu for Restaurant=Logging Test Restaurant")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Created MenuItem=Logging Item")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_id}] Added MenuItem=Logging Item to Menu=Logging Menu")

        service.call
      end
    end

    describe "performance considerations" do
      let(:large_json_data) do
        {
          "restaurants" => Array.new(5) do |i|
            {
              "name" => "Restaurant #{i}",
              "menus" => Array.new(3) do |j|
                {
                  "name" => "Menu #{i}-#{j}",
                  "menu_items" => Array.new(10) do |k|
                    { "name" => "Item #{i}-#{j}-#{k}", "price" => 10.0 + k }
                  end
                }
              end
            }
          end
        }
      end

      let(:large_service) { described_class.new(large_json_data, restaurant_import_id) }

      it "processes large datasets efficiently" do
        expect {
          result = large_service.call

          expect(result[:created_restaurants_count]).to eq(5)
          expect(result[:created_menus_count]).to eq(15)
          expect(result[:created_menu_items_count]).to eq(150)
          expect(result[:linked_menu_items_count]).to eq(150)
        }.to change(Restaurant, :count).by(5)
          .and change(Menu, :count).by(15)
          .and change(MenuItem, :count).by(150)
          .and change(MenuMenuItem, :count).by(150)
      end
    end
  end
end
