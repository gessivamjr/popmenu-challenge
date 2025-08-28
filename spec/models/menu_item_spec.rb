require 'rails_helper'

RSpec.describe MenuItem, type: :model do
  subject { MenuItem.new(name: "Test Item") }

  it { should have_many(:menu_menu_items) }
  it { should have_many(:menus).through(:menu_menu_items) }
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
end
