class MenuItem < ApplicationRecord
  has_and_belongs_to_many :menus

  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  scope :available, ->(available) { where(available: available) }
  scope :by_category, ->(category) { where(category: category) }
  scope :cheap, -> { where("price < ?", 10) }
  scope :expensive, -> { where("price > ?", 100) }
  scope :on_menu, ->(menu) { joins(:menus).where(menus: { id: menu.id }) }
  scope :on_multiple_menus, -> { joins(:menus).group("menu_items.id").having("COUNT(menus.id) > 1") }
  scope :for_restaurant, ->(restaurant) { joins(menus: :restaurant).where(restaurants: { id: restaurant.id }) }
end
