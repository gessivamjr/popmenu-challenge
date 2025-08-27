class Menu < ApplicationRecord
  has_many :menu_items, dependent: :destroy

  validates :name, presence: true
  validates :starts_at, :ends_at, presence: true, if: -> { starts_at.present? || ends_at.present? }
  validates :starts_at, :ends_at, inclusion: { in: 0..23, message: "must be a valid hour (0-23)" }, if: -> { starts_at.present? && ends_at.present? }
  validate :valid_start_time

  scope :active, ->(active) { where(active: active) }
  scope :by_category, ->(category) { where(category: category) }

  def as_json(options = {})
    super(options.merge(include: :menu_items))
  end

  private

  def valid_start_time
    if starts_at.present? && ends_at.present? && starts_at >= ends_at
      errors.add(:base, "Start time must be before end time")
    end
  end
end
