class Menu < ApplicationRecord
  has_many :menu_items, dependent: :destroy

  validates :name, presence: true
  validate :valid_start_time

  private

  def valid_start_time
    if starts_at.present? && ends_at.present? && starts_at >= ends_at
      errors.add(:base, "Start time must be before end time")
    end
  end
end
