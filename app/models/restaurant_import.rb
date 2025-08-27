class RestaurantImport < ApplicationRecord
  has_one_attached :file

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }

  validates :file, presence: true
end
