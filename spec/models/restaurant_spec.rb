require 'rails_helper'

RSpec.describe Restaurant, type: :model do
  it { should have_many(:menus).dependent(:destroy) }
  it { should have_many(:menu_items).through(:menus) }

  it { should validate_presence_of(:name) }
end
