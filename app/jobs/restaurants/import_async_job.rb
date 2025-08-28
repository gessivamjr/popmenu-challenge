module Restaurants
  class ImportAsyncJob < ApplicationJob
    queue_as :default

    def perform(restaurant_import_id)
      import = RestaurantImport.find(restaurant_import_id)
      import.update!(status: "processing", started_at: Time.current)
      RestaurantImportLogger.info("[#{import.id}] Start processing")

      unless import.file.attached?
        import.update!(status: "failed", error_message: "No file attached", finished_at: Time.current)
        RestaurantImportLogger.error("[#{import.id}] No file attached")
        return
      end

      result = ImportService.call(json: JSON.parse(import.file.download), restaurant_import_id: import.id)

      import.update!(status: "completed", finished_at: Time.current, **result)
      RestaurantImportLogger.info("[#{import.id}] Process completed")
    rescue ActiveRecord::RecordNotFound
      RestaurantImportLogger.error("[#{restaurant_import_id}] Import record not found")
      raise
    rescue => e
      RestaurantImportLogger.error("[#{import.id}] exception=#{e.class} msg=#{e.message}")
      import.update!(status: "failed", error_message: e.message, finished_at: Time.current)
      raise
    end
  end
end
