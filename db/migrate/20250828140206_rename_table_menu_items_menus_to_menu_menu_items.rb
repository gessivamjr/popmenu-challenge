class RenameTableMenuItemsMenusToMenuMenuItems < ActiveRecord::Migration[8.0]
  def change
    rename_table :menu_items_menus, :menu_menu_items
  end
end
