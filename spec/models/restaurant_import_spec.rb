require 'rails_helper'

RSpec.describe RestaurantImport, type: :model do
  it { should validate_presence_of(:file) }
  it { should have_one_attached(:file) }
  it do
    should define_enum_for(:status)
      .with_values(pending: "pending",
                   processing: "processing",
                   completed: "completed",
                   failed: "failed")
      .backed_by_column_of_type(:string)
  end
end
