require 'rails_helper'

RSpec.describe Menu, type: :model do
  it { should have_many(:menu_items).dependent(:destroy) }
  it { should validate_presence_of(:name) }

  describe 'valid_start_time validation' do
    it 'is valid when starts_at is before ends_at' do
      menu = Menu.new(name: 'Test Menu', starts_at: 9, ends_at: 17)
      expect(menu).to be_valid
    end

    context 'it skips validation when' do
      it 'starts_at is nil' do
        menu = Menu.new(name: 'Test Menu', starts_at: nil, ends_at: 17)
        expect(menu).to be_valid
      end

      it 'ends_at is nil' do
        menu = Menu.new(name: 'Test Menu', starts_at: 9, ends_at: nil)
        expect(menu).to be_valid
      end

      it 'both times are nil' do
        menu = Menu.new(name: 'Test Menu', starts_at: nil, ends_at: nil)
        expect(menu).to be_valid
      end
    end

    context 'it is invalid' do
      it 'when starts_at is equal to ends_at' do
        menu = Menu.new(name: 'Test Menu', starts_at: 12, ends_at: 12)
        expect(menu).not_to be_valid
        expect(menu.errors[:base]).to include('Start time must be before end time')
      end

      it 'when starts_at is after ends_at' do
        menu = Menu.new(name: 'Test Menu', starts_at: 17, ends_at: 9)
        expect(menu).not_to be_valid
        expect(menu.errors[:base]).to include('Start time must be before end time')
      end
    end
  end
end
