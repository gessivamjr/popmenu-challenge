class RestaurantImportController < ApplicationController
  def import
    validation_error = validate_json_file_content(restaurant_import_params)

    if validation_error
      return render json: { error: validation_error }, status: :unprocessable_content
    end

    restaurant_import = RestaurantImport.new
    restaurant_import.file.attach(restaurant_import_params)
    restaurant_import.save!

    Restaurants::ImportAsyncJob.perform_later(restaurant_import.id)

    render json: { message: "Import scheduled to be processed" }, status: :ok
  rescue ActionController::ParameterMissing => e
    render json: { error: "Missing required parameter: #{e.param}" }, status: :bad_request
  end

  private

  def restaurant_import_params
    params.expect(:file)
  end

  def validate_json_file_content(file)
    unless file.original_filename&.downcase&.end_with?(".json")
      return "File must be a JSON file (.json extension required)"
    end

    unless json_content_type?(file)
      return "File must have a valid JSON content type"
    end

    unless valid_json_content?(file)
      return "File must contain valid JSON content"
    end

    nil
  end

  def json_content_type?(file)
    valid_types = [ "application/json", "text/json", "text/plain" ]
    valid_types.include?(file.content_type)
  end

  def valid_json_content?(file)
    return false unless file

    begin
      content = file.read
      file.rewind

      JSON.parse(content)

      true
    rescue JSON::ParserError, StandardError => e
      file.rewind if file.respond_to?(:rewind)

      false
    end
  end
end
