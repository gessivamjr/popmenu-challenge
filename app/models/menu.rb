class Menu < ApplicationRecord
  belongs_to :restaurant
  has_many :menu_item_menus, dependent: :destroy
  has_many :menu_items, through: :menu_item_menus

  validates :name, presence: true
  validates :starts_at, :ends_at, presence: true, if: -> { starts_at.present? || ends_at.present? }
  validates :starts_at, :ends_at, inclusion: { in: 0..23, message: "must be a valid hour (0-23)" }, if: -> { starts_at.present? && ends_at.present? }
  validate :valid_start_time

  scope :active, ->(active) { where(active: active) }
  scope :by_category, ->(category) { where(category: category) }
  scope :with_item, ->(menu_item) { joins(:menu_items).where(menu_items: { id: menu_item.id }) }
  scope :with_item_name, ->(item_name) { joins(:menu_items).where(menu_items: { name: item_name }) }

  def as_json(options = {})
    super(options.merge(
      include: { menu_item_menus: { methods: :name } },
      except: [ :created_at, :updated_at, :restaurant_id ]
    ))
  end

  def add_menu_item(menu_item:, attributes:)
    menu_item_menus.create!(menu_item:, **attributes)
  end

  private

  def valid_start_time
    if starts_at.present? && ends_at.present? && starts_at >= ends_at
      errors.add(:base, "Start time must be before end time")
    end
  end
end
