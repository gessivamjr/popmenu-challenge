class MenuItem < ApplicationRecord
  belongs_to :menu

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  scope :available, ->(available) { where(available: available) }
  scope :by_category, ->(category) { where(category: category) }
  scope :cheap, -> { where("price < ?", 10) }
  scope :expensive, -> { where("price > ?", 100) }
end
