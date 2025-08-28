class Restaurant < ApplicationRecord
  has_many :menus, dependent: :destroy
  has_many :menu_items, through: :menus

  validates :name, presence: true

  def as_json(options = {})
    super(options.merge(include: {
      menus: {
        only: [ :id, :name, :description, :category, :active, :starts_at, :ends_at ],
        include: {
          menu_menu_items: {
            only: [ :id, :price, :currency, :available, :description, :category, :image_url, :prep_time_minutes ],
            methods: :name
          }
        }
      }
    }))
  end
end
