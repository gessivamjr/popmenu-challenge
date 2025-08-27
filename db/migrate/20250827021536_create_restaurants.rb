class CreateRestaurants < ActiveRecord::Migration[8.0]
  def change
    create_table :restaurants do |t|
      t.string :name, null: false
      t.text :description
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :phone_number
      t.string :email
      t.string :website_url
      t.string :logo_url
      t.string :cover_image_url

      t.timestamps
    end
  end
end
