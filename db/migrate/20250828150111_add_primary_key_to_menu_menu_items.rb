class AddPrimaryKeyToMenuMenuItems < ActiveRecord::Migration[8.0]
  def change
    add_column :menu_menu_items, :id, :primary_key
  end
end
