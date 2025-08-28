require 'rails_helper'

RSpec.describe "RestaurantImports", type: :request do
  describe "POST /restaurant/import" do
    let(:valid_json_content) { '{"restaurants": [{"name": "Test Restaurant", "address": "123 Main St"}]}' }
    let(:invalid_json_content) { '{"restaurants": [{"name": "Test Restaurant", "address":}]}' }

    before do
      ActiveStorage::Attachment.all.each(&:purge)
    end

    context "Happy path" do
      context "with valid JSON file (application/json)" do
        let(:valid_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(valid_json_content),
            "application/json",
            original_filename: "restaurants.json"
          )
        end

        it "creates a restaurant import record" do
          expect {
            post "/restaurant/import", params: { file: valid_file }
          }.to change(RestaurantImport, :count).by(1)

          expect(response).to have_http_status(:ok)
          expect(json['message']).to eq("Import scheduled to be processed")
        end

        it "attaches the file to the restaurant import" do
          post "/restaurant/import", params: { file: valid_file }

          restaurant_import = RestaurantImport.last
          expect(restaurant_import.file).to be_attached
          expect(restaurant_import.file.filename.to_s).to eq("restaurants.json")
          expect(restaurant_import.file.content_type).to eq("application/json")
        end

        it "sets default status to pending" do
          post "/restaurant/import", params: { file: valid_file }

          restaurant_import = RestaurantImport.last
          expect(restaurant_import.status).to eq("pending")
        end

        it "schedules the import job" do
          expect(Restaurants::ImportAsyncJob).to receive(:perform_later).with(kind_of(Integer))

          post "/restaurant/import", params: { file: valid_file }

          expect(response).to have_http_status(:ok)
        end

        it "preserves file content correctly" do
          post "/restaurant/import", params: { file: valid_file }

          restaurant_import = RestaurantImport.last
          file_content = restaurant_import.file.download
          expect(file_content).to eq(valid_json_content)
        end
      end

      context "with valid text/json JSON file" do
        let(:text_json_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(valid_json_content),
            "text/json",
            original_filename: "restaurants.json"
          )
        end

        it "accepts text/json content type" do
          expect {
            post "/restaurant/import", params: { file: text_json_file }
          }.to change(RestaurantImport, :count).by(1)

          expect(response).to have_http_status(:ok)
          expect(json['message']).to eq("Import scheduled to be processed")
        end
      end

      context "with valid text/plain JSON file" do
        let(:text_plain_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(valid_json_content),
            "text/plain",
            original_filename: "restaurants.json"
          )
        end

        it "accepts text/plain content type" do
          expect {
            post "/restaurant/import", params: { file: text_plain_file }
          }.to change(RestaurantImport, :count).by(1)

          expect(response).to have_http_status(:ok)
          expect(json['message']).to eq("Import scheduled to be processed")
        end
      end

      context "with special characters in filename" do
        let(:special_filename_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(valid_json_content),
            "application/json",
            original_filename: "restaurants with spaces & special-chars.json"
          )
        end

        it "handles filenames with special characters" do
          post "/restaurant/import", params: { file: special_filename_file }

          expect(response).to have_http_status(:ok)
          restaurant_import = RestaurantImport.last
          expect(restaurant_import.file.filename.to_s).to eq("restaurants with spaces & special-chars.json")
        end
      end
    end

    context "File extension validation" do
      context "when file doesn't have .json extension" do
        let(:non_json_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(valid_json_content),
            "application/json",
            original_filename: "restaurants.txt"
          )
        end

        it "returns validation error" do
          post "/restaurant/import", params: { file: non_json_file }

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['error']).to eq("File must be a JSON file (.json extension required)")
        end

        it "does not create restaurant import record" do
          expect {
            post "/restaurant/import", params: { file: non_json_file }
          }.not_to change(RestaurantImport, :count)
        end

        it "does not schedule the import job" do
          expect(Restaurants::ImportAsyncJob).not_to receive(:perform_later)

          post "/restaurant/import", params: { file: non_json_file }
        end
      end

      context "when file has uppercase .JSON extension" do
        let(:uppercase_json_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(valid_json_content),
            "application/json",
            original_filename: "restaurants.JSON"
          )
        end

        it "accepts uppercase extension" do
          post "/restaurant/import", params: { file: uppercase_json_file }

          expect(response).to have_http_status(:ok)
          expect(json['message']).to eq("Import scheduled to be processed")
        end
      end

      context "when filename is empty string" do
        let(:empty_filename_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(valid_json_content),
            "application/json",
            original_filename: ""
          )
        end

        it "returns validation error" do
          post "/restaurant/import", params: { file: empty_filename_file }

          expect(response).to have_http_status(:bad_request)
          expect(json['error']).to eq("Missing required parameter: file")
        end
      end
    end

    context "Content type validation" do
      context "when file has invalid content type" do
        let(:invalid_content_type_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(valid_json_content),
            "application/pdf",
            original_filename: "restaurants.json"
          )
        end

        it "returns validation error" do
          post "/restaurant/import", params: { file: invalid_content_type_file }

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['error']).to eq("File must have a valid JSON content type")
        end

        it "does not create restaurant import record" do
          expect {
            post "/restaurant/import", params: { file: invalid_content_type_file }
          }.not_to change(RestaurantImport, :count)
        end
      end

      context "when content type is nil" do
        let(:no_content_type_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(valid_json_content),
            nil,
            original_filename: "restaurants.json"
          )
        end

        it "returns validation error" do
          post "/restaurant/import", params: { file: no_content_type_file }

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['error']).to eq("File must have a valid JSON content type")
        end
      end
    end

    context "JSON content validation" do
      context "when file contains invalid JSON" do
        let(:invalid_json_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(invalid_json_content),
            "application/json",
            original_filename: "restaurants.json"
          )
        end

        it "returns validation error" do
          post "/restaurant/import", params: { file: invalid_json_file }

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['error']).to eq("File must contain valid JSON content")
        end

        it "does not create restaurant import record" do
          expect {
            post "/restaurant/import", params: { file: invalid_json_file }
          }.not_to change(RestaurantImport, :count)
        end
      end

      context "when file is empty" do
        let(:empty_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(""),
            "application/json",
            original_filename: "restaurants.json"
          )
        end

        it "returns validation error" do
          post "/restaurant/import", params: { file: empty_file }

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['error']).to eq("File must contain valid JSON content")
        end
      end

      context "when file contains only whitespace" do
        let(:whitespace_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new("   \n\t  "),
            "application/json",
            original_filename: "restaurants.json"
          )
        end

        it "returns validation error" do
          post "/restaurant/import", params: { file: whitespace_file }

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['error']).to eq("File must contain valid JSON content")
        end
      end

      context "when file contains malformed JSON" do
        let(:malformed_json_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new('{"restaurants": [{"name": "Test}'),
            "application/json",
            original_filename: "restaurants.json"
          )
        end

        it "returns validation error" do
          post "/restaurant/import", params: { file: malformed_json_file }

          expect(response).to have_http_status(:unprocessable_content)
          expect(json['error']).to eq("File must contain valid JSON content")
        end
      end
    end

    context "Parameter validation" do
      context "when file parameter is missing" do
        it "returns bad request error" do
          post "/restaurant/import", params: {}

          expect(response).to have_http_status(:bad_request)
          expect(json['error']).to eq("Missing required parameter: file")
        end

        it "does not create restaurant import record" do
          expect {
            post "/restaurant/import", params: {}
          }.not_to change(RestaurantImport, :count)
        end

        it "does not schedule the import job" do
          expect(Restaurants::ImportAsyncJob).not_to receive(:perform_later)

          post "/restaurant/import", params: {}
        end
      end

      context "when file parameter is nil" do
        it "returns bad request error" do
          post "/restaurant/import", params: { file: nil }

          expect(response).to have_http_status(:bad_request)
          expect(json['error']).to eq("Missing required parameter: file")
        end
      end
    end

    context "Edge cases" do
      context "with large JSON file" do
        let(:large_json_content) do
          { restaurants: Array.new(1000) { |i| { name: "Restaurant #{i}", address: "#{i} Main St" } } }.to_json
        end
        let(:large_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(large_json_content),
            "application/json",
            original_filename: "large_restaurants.json"
          )
        end

        it "handles large files correctly" do
          post "/restaurant/import", params: { file: large_file }

          expect(response).to have_http_status(:ok)
          expect(json['message']).to eq("Import scheduled to be processed")

          restaurant_import = RestaurantImport.last
          expect(restaurant_import.file).to be_attached
          expect(restaurant_import.file.download.length).to be > 10000
        end
      end

      context "with minimum valid JSON" do
        let(:minimal_json_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new('{}'),
            "application/json",
            original_filename: "minimal.json"
          )
        end

        it "accepts minimal valid JSON" do
          post "/restaurant/import", params: { file: minimal_json_file }

          expect(response).to have_http_status(:ok)
          expect(json['message']).to eq("Import scheduled to be processed")
        end
      end

      context "with complex nested JSON" do
        let(:complex_json_content) do
          {
            restaurants: [
              {
                name: "Complex Restaurant",
                address: "123 Main St",
                contact: {
                  phone: "555-1234",
                  email: "test@example.com"
                },
                menus: [
                  {
                    name: "Dinner Menu",
                    items: [
                      { name: "Pasta", price: 15.99, ingredients: [ "pasta", "sauce", "cheese" ] }
                    ]
                  }
                ]
              }
            ]
          }.to_json
        end
        let(:complex_json_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(complex_json_content),
            "application/json",
            original_filename: "complex_restaurants.json"
          )
        end

        it "handles complex nested JSON structures" do
          post "/restaurant/import", params: { file: complex_json_file }

          expect(response).to have_http_status(:ok)
          expect(json['message']).to eq("Import scheduled to be processed")

          restaurant_import = RestaurantImport.last
          parsed_content = JSON.parse(restaurant_import.file.download)
          expect(parsed_content["restaurants"].first["contact"]["email"]).to eq("test@example.com")
        end
      end

      context "with JSON containing special characters" do
        let(:special_chars_json_content) do
          {
            restaurants: [
              {
                name: "Café Münün & Restaurant™",
                address: "123 Main St, São Paulo",
                description: "A special place with émojis 🍕🍺 and ñice food"
              }
            ]
          }.to_json
        end
        let(:special_chars_file) do
          Rack::Test::UploadedFile.new(
            StringIO.new(special_chars_json_content),
            "application/json",
            original_filename: "special_restaurants.json"
          )
        end

        it "handles JSON with special characters and emojis" do
          post "/restaurant/import", params: { file: special_chars_file }

          expect(response).to have_http_status(:ok)
          expect(json['message']).to eq("Import scheduled to be processed")

          restaurant_import = RestaurantImport.last
          parsed_content = JSON.parse(restaurant_import.file.download)
          expect(parsed_content["restaurants"].first["name"]).to eq("Café Münün & Restaurant™")
          expect(parsed_content["restaurants"].first["description"]).to include("🍕🍺")
        end
      end
    end

    context "Job scheduling" do
      let(:valid_file) do
        Rack::Test::UploadedFile.new(
          StringIO.new(valid_json_content),
          "application/json",
          original_filename: "restaurants.json"
        )
      end

      it "schedules job with correct restaurant import id" do
        expect(Restaurants::ImportAsyncJob).to receive(:perform_later) do |import_id|
          expect(import_id).to be_a(Integer)
          expect(RestaurantImport.find(import_id)).to be_present
        end

        post "/restaurant/import", params: { file: valid_file }
      end

      it "does not schedule job if validation fails" do
        invalid_file = Rack::Test::UploadedFile.new(
          StringIO.new(valid_json_content),
          "application/json",
          original_filename: "restaurants.txt"
        )

        expect(Restaurants::ImportAsyncJob).not_to receive(:perform_later)

        post "/restaurant/import", params: { file: invalid_file }
      end
    end

    context "Database transactions" do
      let(:valid_file) do
        Rack::Test::UploadedFile.new(
          StringIO.new(valid_json_content),
          "application/json",
          original_filename: "restaurants.json"
        )
      end

      it "creates record and schedules job in sequence" do
        allow(Restaurants::ImportAsyncJob).to receive(:perform_later) do |import_id|
          expect(RestaurantImport.find(import_id)).to be_present
          expect(RestaurantImport.find(import_id).file).to be_attached
        end

        post "/restaurant/import", params: { file: valid_file }

        expect(response).to have_http_status(:ok)
      end
    end

    context "File handling edge cases" do
      it "handles file rewind properly on validation" do
        invalid_file = Rack::Test::UploadedFile.new(
          StringIO.new('invalid json content'),
          "application/json",
          original_filename: "restaurants.json"
        )

        expect {
          post "/restaurant/import", params: { file: invalid_file }
        }.not_to raise_error

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "handles nil file gracefully in validation" do
        file_double = double("file")
        allow(file_double).to receive(:original_filename).and_return(nil)
        allow(file_double).to receive(:content_type).and_return("application/json")
        allow_any_instance_of(RestaurantImportController).to receive(:restaurant_import_params).and_return(file_double)

        post "/restaurant/import", params: { file: nil }

        expect(response).to have_http_status(:unprocessable_content)
        expect(json['error']).to eq("File must be a JSON file (.json extension required)")
      end
    end
  end
end
