class CreateMenuItems < ActiveRecord::Migration[8.0]
  def change
    create_table :menu_items do |t|
      t.string :name, null: false
      t.decimal :price, null: false, precision: 6, scale: 2
      t.string :currency, null: false, default: "USD"
      t.text :description
      t.string :category
      t.boolean :available, default: true
      t.string :image_url
      t.integer :prep_time_minutes
      t.references :menu, null: false, foreign_key: true

      t.timestamps
    end
  end
end
