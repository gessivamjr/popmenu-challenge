class CreateJoinTableMenuItemsMenus < ActiveRecord::Migration[8.0]
  def change
    create_join_table :menu_items, :menus do |t|
      t.index [ :menu_item_id, :menu_id ], unique: true
      t.index [ :menu_id, :menu_item_id ]
    end

    add_foreign_key :menu_items_menus, :menu_items
    add_foreign_key :menu_items_menus, :menus

    remove_column :menu_items, :menu_id, :integer
  end
end
