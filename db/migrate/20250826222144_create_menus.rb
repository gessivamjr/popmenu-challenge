class CreateMenus < ActiveRecord::Migration[8.0]
  def change
    create_table :menus do |t|
      t.string :name, null: false
      t.text :description
      t.string :category
      t.boolean :active, default: true
      t.integer :starts_at
      t.integer :ends_at

      t.timestamps
    end
  end
end
