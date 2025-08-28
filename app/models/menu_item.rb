class MenuItem < ApplicationRecord
  has_many :menu_item_menus, dependent: :destroy
  has_many :menus, through: :menu_item_menus

  validates :name, presence: true, uniqueness: true

  scope :on_multiple_menus, -> { joins(:menus).group("menu_items.id").having("COUNT(menus.id) > 1") }
end
