require 'rails_helper'

RSpec.describe MenuItem, type: :model do
  it { should belong_to(:menu) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:price) }
  it { should validate_presence_of(:currency) }
  it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
end
