restaurant_import_log_path = Rails.root.join("log", "restaurant_import.log")

RestaurantImportLogger = Logger.new(restaurant_import_log_path, 5, 5 * 1024 * 1024)
RestaurantImportLogger.level = Logger::DEBUG
RestaurantImportLogger.progname = "RestaurantImport"

RestaurantImportLogger.formatter = proc do |severity, timestamp, progname, msg|
  "#{timestamp.utc.iso8601} | #{progname} | #{severity} | #{msg}\n"
end
