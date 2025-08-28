class AddColumnsToJoinTableAndDropFromMenuItem < ActiveRecord::Migration[8.0]
  def up
    change_table :menu_items_menus, bulk: true do |t|
      t.text :description
      t.string :category
      t.decimal :price, precision: 6, scale: 2, null: false
      t.string :currency, default: "USD", null: false
      t.boolean :available, default: true
      t.string :image_url
      t.integer :prep_time_minutes
    end

    change_table :menu_items, bulk: true do |t|
      t.remove :price, :description, :category, :available, :image_url, :prep_time_minutes, :currency
    end
  end

  def down
    change_table :menu_items, bulk: true do |t|
      t.decimal :price, precision: 6, scale: 2, null: false
      t.text :description
      t.string :category
      t.boolean :available, default: true
      t.string :image_url
      t.integer :prep_time_minutes
      t.string :currency, default: "USD", null: false
    end

    change_table :menu_items_menus, bulk: true do |t|
      t.remove :description, :category, :price, :currency, :available, :image_url, :prep_time_minutes
    end
  end
end
