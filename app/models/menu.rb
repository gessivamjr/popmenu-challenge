class Menu < ApplicationRecord
  belongs_to :restaurant
  has_many :menu_menu_items, dependent: :destroy
  has_many :menu_items, through: :menu_menu_items

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
      include: { menu_menu_items: { methods: :name } }
    ))
  end

  def add_menu_item(menu_item:, attributes:)
    menu_item = MenuMenuItem.new(menu_item:, **attributes)
    menu_item.menu = self

    unless menu_item.valid?
      return { success: false, errors: menu_item.errors.full_messages }
    end

    { success: menu_item.save!, errors: [] }
  end

  def update_menu_item(menu_item:, attributes:)
    unless menu_item.update(attributes)
      return { success: false, errors: menu_item.errors.full_messages }
    end

    { success: true, errors: [] }
  end

  private

  def valid_start_time
    if starts_at.present? && ends_at.present? && starts_at >= ends_at
      errors.add(:base, "Start time must be before end time")
    end
  end
end
