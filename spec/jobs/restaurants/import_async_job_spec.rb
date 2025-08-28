require 'rails_helper'

RSpec.describe Restaurants::ImportAsyncJob, type: :job do
  include ActiveJob::TestHelper

  let(:restaurant_import) { create(:restaurant_import, :with_valid_json_file) }
  let(:valid_json_data) do
    {
      "restaurants" => [
        {
          "name" => "Test Restaurant",
          "menus" => [
            {
              "name" => "Test Menu",
              "menu_items" => [
                { "name" => "Test Item", "price" => 12.99 }
              ]
            }
          ]
        }
      ]
    }
  end
  let(:import_service_result) do
    {
      created_restaurants_count: 1,
      created_menus_count: 1,
      created_menu_items_count: 1,
      linked_menu_items_count: 1,
      failed_restaurants_count: 0,
      failed_menus_count: 0,
      failed_menu_items_count: 0,
      failed_links_count: 0
    }
  end

  before do
    allow(RestaurantImportLogger).to receive(:info)
    allow(RestaurantImportLogger).to receive(:error)

    allow(Time).to receive(:current).and_return(Time.parse("2023-01-01 12:00:00 UTC"))
  end

  describe "#perform" do
    context "with successful import processing" do
      before do
        allow(JSON).to receive(:parse).and_return(valid_json_data)
        allow(Restaurants::ImportService).to receive(:call).and_return(import_service_result)
      end

      it "processes the import successfully" do
        expect {
          described_class.perform_now(restaurant_import.id)
        }.to change { restaurant_import.reload.status }.from("pending").to("completed")
      end

      it "updates import status to processing at start" do
        described_class.perform_now(restaurant_import.id)

        restaurant_import.reload
        expect(restaurant_import.started_at).to eq(Time.current)
      end

      it "updates import with service results on completion" do
        described_class.perform_now(restaurant_import.id)

        restaurant_import.reload
        expect(restaurant_import.status).to eq("completed")
        expect(restaurant_import.finished_at).to eq(Time.current)
        expect(restaurant_import.created_restaurants_count).to eq(1)
        expect(restaurant_import.created_menus_count).to eq(1)
        expect(restaurant_import.created_menu_items_count).to eq(1)
        expect(restaurant_import.linked_menu_items_count).to eq(1)
        expect(restaurant_import.failed_restaurants_count).to eq(0)
        expect(restaurant_import.failed_menus_count).to eq(0)
        expect(restaurant_import.failed_menu_items_count).to eq(0)
        expect(restaurant_import.failed_links_count).to eq(0)
      end

      it "calls ImportService with correct parameters" do
        expect(Restaurants::ImportService).to receive(:call).with(
          json: valid_json_data,
          restaurant_import_id: restaurant_import.id
        )

        described_class.perform_now(restaurant_import.id)
      end

      it "logs start and completion messages" do
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import.id}] Start processing")
        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import.id}] Process completed")

        described_class.perform_now(restaurant_import.id)
      end

      it "parses JSON from attached file" do
        expect(JSON).to receive(:parse).with(restaurant_import.file.download)

        described_class.perform_now(restaurant_import.id)
      end
    end

    context "when import record does not exist" do
      it "raises ActiveRecord::RecordNotFound and logs specific error message" do
        expect(RestaurantImportLogger).to receive(:error).with("[99999] Import record not found")

        expect {
          described_class.perform_now(99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when no file is attached" do
      it "updates status to failed with error message" do
        restaurant_import_without_file = create(:restaurant_import, :with_valid_json_file)
        allow_any_instance_of(RestaurantImport).to receive(:file).and_return(double("file", attached?: false))

        described_class.perform_now(restaurant_import_without_file.id)

        restaurant_import_without_file.reload
        expect(restaurant_import_without_file.status).to eq("failed")
        expect(restaurant_import_without_file.error_message).to eq("No file attached")
        expect(restaurant_import_without_file.finished_at).to eq(Time.current)
      end

      it "logs error message" do
        restaurant_import_without_file = create(:restaurant_import, :with_valid_json_file)
        allow_any_instance_of(RestaurantImport).to receive(:file).and_return(double("file", attached?: false))

        expect(RestaurantImportLogger).to receive(:error).with("[#{restaurant_import_without_file.id}] No file attached")

        described_class.perform_now(restaurant_import_without_file.id)
      end

      it "returns early without calling ImportService" do
        restaurant_import_without_file = create(:restaurant_import, :with_valid_json_file)
        allow_any_instance_of(RestaurantImport).to receive(:file).and_return(double("file", attached?: false))

        expect(Restaurants::ImportService).not_to receive(:call)

        described_class.perform_now(restaurant_import_without_file.id)
      end

      it "still logs start processing message" do
        restaurant_import_without_file = create(:restaurant_import, :with_valid_json_file)
        allow_any_instance_of(RestaurantImport).to receive(:file).and_return(double("file", attached?: false))

        expect(RestaurantImportLogger).to receive(:info).with("[#{restaurant_import_without_file.id}] Start processing")

        described_class.perform_now(restaurant_import_without_file.id)
      end
    end

    context "when JSON parsing fails" do
      it "handles JSON parsing errors" do
        restaurant_import_for_json_error = create(:restaurant_import, :with_valid_json_file)
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError.new("Invalid JSON"))

        expect {
          described_class.perform_now(restaurant_import_for_json_error.id)
        }.to raise_error(JSON::ParserError)

        restaurant_import_for_json_error.reload
        expect(restaurant_import_for_json_error.status).to eq("failed")
        expect(restaurant_import_for_json_error.error_message).to eq("Invalid JSON")
        expect(restaurant_import_for_json_error.finished_at).to eq(Time.current)
      end

      it "logs the exception" do
        restaurant_import_for_json_error = create(:restaurant_import, :with_valid_json_file)
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError.new("Invalid JSON"))
        expect(RestaurantImportLogger).to receive(:error).with("[#{restaurant_import_for_json_error.id}] exception=JSON::ParserError msg=Invalid JSON")

        expect {
          described_class.perform_now(restaurant_import_for_json_error.id)
        }.to raise_error(JSON::ParserError)
      end
    end

    context "when ImportService fails" do
      before do
        allow(JSON).to receive(:parse).and_return(valid_json_data)
        allow(Restaurants::ImportService).to receive(:call).and_raise(StandardError.new("Service failed"))
      end

      it "handles ImportService errors" do
        expect {
          described_class.perform_now(restaurant_import.id)
        }.to raise_error(StandardError)

        restaurant_import.reload
        expect(restaurant_import.status).to eq("failed")
        expect(restaurant_import.error_message).to eq("Service failed")
        expect(restaurant_import.finished_at).to eq(Time.current)
      end

      it "logs the exception" do
        expect(RestaurantImportLogger).to receive(:error).with("[#{restaurant_import.id}] exception=StandardError msg=Service failed")

        expect {
          described_class.perform_now(restaurant_import.id)
        }.to raise_error(StandardError)
      end
    end

    context "when file download fails" do
      it "handles file download errors" do
        restaurant_import_for_download_error = create(:restaurant_import, :with_valid_json_file)
        file_double = double("file", attached?: true, download: nil)
        allow(file_double).to receive(:download).and_raise(StandardError.new("Download failed"))
        allow_any_instance_of(RestaurantImport).to receive(:file).and_return(file_double)

        expect {
          described_class.perform_now(restaurant_import_for_download_error.id)
        }.to raise_error(StandardError)

        restaurant_import_for_download_error.reload
        expect(restaurant_import_for_download_error.status).to eq("failed")
        expect(restaurant_import_for_download_error.error_message).to eq("Download failed")
        expect(restaurant_import_for_download_error.finished_at).to eq(Time.current)
      end

      it "logs the exception" do
        restaurant_import_for_download_error = create(:restaurant_import, :with_valid_json_file)
        file_double = double("file", attached?: true, download: nil)
        allow(file_double).to receive(:download).and_raise(StandardError.new("Download failed"))
        allow_any_instance_of(RestaurantImport).to receive(:file).and_return(file_double)
        expect(RestaurantImportLogger).to receive(:error).with("[#{restaurant_import_for_download_error.id}] exception=StandardError msg=Download failed")

        expect {
          described_class.perform_now(restaurant_import_for_download_error.id)
        }.to raise_error(StandardError)
      end
    end

    context "when import update fails during error handling" do
      it "rescues update failures during error handling" do
        restaurant_import_for_update_error = create(:restaurant_import, :with_valid_json_file)
        allow(JSON).to receive(:parse).and_raise(StandardError.new("Parse failed"))
        allow(restaurant_import_for_update_error).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(restaurant_import_for_update_error))

        expect {
          described_class.perform_now(restaurant_import_for_update_error.id)
        }.to raise_error(StandardError, "Parse failed")
      end
    end

    context "with different ImportService results" do
      before do
        allow(JSON).to receive(:parse).and_return(valid_json_data)
      end

      it "handles partial success results" do
        partial_result = {
          created_restaurants_count: 2,
          created_menus_count: 3,
          created_menu_items_count: 5,
          linked_menu_items_count: 4,
          failed_restaurants_count: 1,
          failed_menus_count: 2,
          failed_menu_items_count: 1,
          failed_links_count: 3
        }
        allow(Restaurants::ImportService).to receive(:call).and_return(partial_result)

        described_class.perform_now(restaurant_import.id)

        restaurant_import.reload
        expect(restaurant_import.status).to eq("completed")
        expect(restaurant_import.created_restaurants_count).to eq(2)
        expect(restaurant_import.created_menus_count).to eq(3)
        expect(restaurant_import.created_menu_items_count).to eq(5)
        expect(restaurant_import.linked_menu_items_count).to eq(4)
        expect(restaurant_import.failed_restaurants_count).to eq(1)
        expect(restaurant_import.failed_menus_count).to eq(2)
        expect(restaurant_import.failed_menu_items_count).to eq(1)
        expect(restaurant_import.failed_links_count).to eq(3)
      end

      it "handles zero counts results" do
        zero_result = {
          created_restaurants_count: 0,
          created_menus_count: 0,
          created_menu_items_count: 0,
          linked_menu_items_count: 0,
          failed_restaurants_count: 0,
          failed_menus_count: 0,
          failed_menu_items_count: 0,
          failed_links_count: 0
        }
        allow(Restaurants::ImportService).to receive(:call).and_return(zero_result)

        described_class.perform_now(restaurant_import.id)

        restaurant_import.reload
        expect(restaurant_import.status).to eq("completed")
        expect(restaurant_import.created_restaurants_count).to eq(0)
        expect(restaurant_import.failed_restaurants_count).to eq(0)
      end
    end

    context "when processing import that's already in progress" do
      before do
        allow(JSON).to receive(:parse).and_return(valid_json_data)
        allow(Restaurants::ImportService).to receive(:call).and_return(import_service_result)
      end

      it "can process import regardless of initial status" do
        restaurant_import.update!(status: "processing")

        described_class.perform_now(restaurant_import.id)

        restaurant_import.reload
        expect(restaurant_import.status).to eq("completed")
      end
    end
  end

  describe "job queue and ActiveJob integration" do
    it "is queued on the default queue" do
      expect(described_class.queue_name).to eq("default")
    end

    it "can be enqueued and performed later" do
      allow(JSON).to receive(:parse).and_return(valid_json_data)
      allow(Restaurants::ImportService).to receive(:call).and_return(import_service_result)

      expect {
        described_class.perform_later(restaurant_import.id)
      }.to have_enqueued_job(described_class).with(restaurant_import.id)

      perform_enqueued_jobs do
        described_class.perform_later(restaurant_import.id)
      end

      restaurant_import.reload
      expect(restaurant_import.status).to eq("completed")
    end
  end

  describe "error handling edge cases" do
    context "when import becomes nil during error handling" do
      before do
        allow(RestaurantImport).to receive(:find).and_return(restaurant_import)
        allow(JSON).to receive(:parse).and_raise(StandardError.new("Test error"))
        allow(restaurant_import).to receive(:update!).and_return(nil)
      end

      it "handles nil import gracefully" do
        expect {
          described_class.perform_now(restaurant_import.id)
        }.to raise_error(StandardError, "Test error")
      end
    end

    context "when logging fails" do
      before do
        allow(JSON).to receive(:parse).and_return(valid_json_data)
        allow(Restaurants::ImportService).to receive(:call).and_return(import_service_result)
        allow(RestaurantImportLogger).to receive(:info).and_raise(StandardError.new("Logging failed"))
      end

      it "continues processing even if logging fails" do
        expect {
          described_class.perform_now(restaurant_import.id)
        }.to raise_error(StandardError, "Logging failed")
      end
    end
  end

  describe "integration with real file content" do
    context "with actual JSON file content" do
      let(:restaurant_import_with_real_content) { create(:restaurant_import, :with_valid_json_file) }

      before do
        allow(Restaurants::ImportService).to receive(:call).and_return(import_service_result)
      end

      it "processes real file content successfully" do
        described_class.perform_now(restaurant_import_with_real_content.id)

        restaurant_import_with_real_content.reload
        expect(restaurant_import_with_real_content.status).to eq("completed")
      end

      it "parses actual JSON content from file" do
        expect(JSON).to receive(:parse).with(restaurant_import_with_real_content.file.download).and_call_original

        described_class.perform_now(restaurant_import_with_real_content.id)
      end
    end
  end
end
