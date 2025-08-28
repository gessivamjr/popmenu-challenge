class ChangeRestaurantImportCountColumns < ActiveRecord::Migration[8.0]
  def change
    change_table :restaurant_imports, bulk: true do |t|
      t.remove :total_count, :success_count, :failure_count

      t.integer :created_restaurants_count, default: 0, null: false
      t.integer :created_menus_count, default: 0, null: false
      t.integer :created_menu_items_count, default: 0, null: false
      t.integer :linked_menu_items_count, default: 0, null: false
      t.integer :failed_restaurants_count, default: 0, null: false
      t.integer :failed_menus_count, default: 0, null: false
      t.integer :failed_menu_items_count, default: 0, null: false
      t.integer :failed_links_count, default: 0, null: false
    end
  end
end
