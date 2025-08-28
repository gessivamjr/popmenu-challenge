require 'rails_helper'

RSpec.describe MenuMenuItem, type: :model do
  it { should belong_to(:menu) }
  it { should belong_to(:menu_item) }
  it { should validate_presence_of(:price) }
  it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
  it { should validate_presence_of(:currency) }
end
