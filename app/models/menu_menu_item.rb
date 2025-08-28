class MenuMenuItem < ApplicationRecord
  belongs_to :menu_item
  belongs_to :menu

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  delegate :name, to: :menu_item

  scope :on_menu, ->(menu_id) { where(menu_id: menu_id) }
  scope :for_restaurant, ->(restaurant_id) { joins(:menu).where(menus: { restaurant_id: restaurant_id }) }
  scope :available, ->(available) { where(available: available) }
  scope :by_category, ->(category) { where(category: category) }
  scope :cheap, -> { where("price < ?", 10) }
  scope :expensive, -> { where("price > ?", 100) }

  def as_json(options = {})
    super(options.merge(
      except: [ :created_at, :updated_at ],
      include: {
        menu: { only: [ :id, :name, :restaurant_id ] }
      },
      methods: :name
    ))
  end
end
