module Restaurants
  class ImportService
    def self.call(json:, restaurant_import_id:)
      new(json, restaurant_import_id).call
    end

    def initialize(json, restaurant_import_id)
      @json = json
      @restaurant_import_id = restaurant_import_id
      @created_restaurants = 0
      @created_menus = 0
      @created_items = 0
      @linked_items = 0
      @failed_restaurants = 0
      @failed_menus = 0
      @failed_items = 0
      @failed_links = 0
    end

    def call
      restaurants = @json["restaurants"] || []

      restaurants.each do |restaurant_hash|
        begin
          restaurant = Restaurant.find_or_create_by!(name: restaurant_hash["name"])
          if restaurant.previously_new_record?
            @created_restaurants += 1
            RestaurantImportLogger.info("[#{@restaurant_import_id}] Created Restaurant=#{restaurant.name}")
          else
            RestaurantImportLogger.info("[#{@restaurant_import_id}] Found Restaurant=#{restaurant.name}")
          end
        rescue => e
          RestaurantImportLogger.error("[#{@restaurant_import_id}] Failed creating Restaurant name=#{restaurant_hash['name']} exception=#{e.class} msg=#{e.message}")
          @failed_restaurants += 1
          next
        end

        (restaurant_hash["menus"] || []).each do |menu_hash|
          begin
            menu = restaurant.menus.find_or_create_by!(name: menu_hash["name"])
            if menu.previously_new_record?
              @created_menus += 1
              RestaurantImportLogger.info("[#{@restaurant_import_id}] Created Menu=#{menu.name} for Restaurant=#{restaurant.name}")
            else
              RestaurantImportLogger.info("[#{@restaurant_import_id}] Found Menu=#{menu.name} for Restaurant=#{restaurant.name}")
            end
          rescue => e
            RestaurantImportLogger.error("[#{@restaurant_import_id}] Failed creating Menu name=#{menu_hash['name']} for Restaurant=#{restaurant.name} exception=#{e.class} msg=#{e.message}")
            @failed_menus += 1
            next
          end

          items = menu_hash["menu_items"] || menu_hash["dishes"] || []
          items.each do |item_hash|
            begin
              item = MenuItem.find_or_create_by!(name: item_hash["name"])

              if item.previously_new_record?
                @created_items += 1
                RestaurantImportLogger.info("[#{@restaurant_import_id}] Created MenuItem=#{item.name}")
              else
                RestaurantImportLogger.info("[#{@restaurant_import_id}] Found MenuItem=#{item.name}")
              end
            rescue => e
              RestaurantImportLogger.error("[#{@restaurant_import_id}] Failed creating MenuItem name=#{item_hash['name']} price=#{item_hash['price']} exception=#{e.class} msg=#{e.message}")
              @failed_items += 1
              next
            end

            unless menu.menu_menu_items.exists?(menu_item_id: item.id)
              result = menu.add_menu_item(menu_item: item, attributes: { price: item_hash["price"] })

              if result[:success]
                RestaurantImportLogger.info("[#{@restaurant_import_id}] Added MenuItem=#{item.name} to Menu=#{menu.name}")
                @linked_items += 1
              else
                RestaurantImportLogger.error("[#{@restaurant_import_id}] Failed adding MenuItem=#{item.name} to Menu=#{menu.name} errors=#{result[:errors].join(", ")}")
                @failed_links += 1
              end
            end
          end
        end
      end

      {
        created_restaurants_count: @created_restaurants,
        created_menus_count: @created_menus,
        created_menu_items_count: @created_items,
        linked_menu_items_count: @linked_items,
        failed_restaurants_count: @failed_restaurants,
        failed_menus_count: @failed_menus,
        failed_menu_items_count: @failed_items,
        failed_links_count: @failed_links
      }
    end
  end
end
