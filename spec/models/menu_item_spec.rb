require 'rails_helper'

RSpec.describe MenuItem, type: :model do
  subject { MenuItem.new(name: "Test Item", price: 10.99, currency: "USD") }

  it { should have_and_belong_to_many(:menus) }
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
  it { should validate_presence_of(:price) }
  it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
  it { should validate_presence_of(:currency) }
end
