class CreateRestaurantImports < ActiveRecord::Migration[8.0]
  def change
    create_table :restaurant_imports do |t|
      t.string :status, null: false, default: "pending"
      t.integer :total_count, default: 0
      t.integer :success_count, default: 0
      t.integer :failure_count, default: 0
      t.datetime :started_at
      t.datetime :finished_at
      t.text :error_message

      t.timestamps
    end
  end
end
