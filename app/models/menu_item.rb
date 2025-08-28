class MenuItem < ApplicationRecord
  has_many :menu_menu_items, dependent: :destroy
  has_many :menus, through: :menu_menu_items

  validates :name, presence: true, uniqueness: true

  scope :on_multiple_menus, -> { joins(:menus).group("menu_items.id").having("COUNT(menus.id) > 1") }
end
