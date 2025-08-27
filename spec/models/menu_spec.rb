require 'rails_helper'

RSpec.describe Menu, type: :model do
  let(:restaurant) { create(:restaurant) }

  it { should have_and_belong_to_many(:menu_items) }
  it { should validate_presence_of(:name) }

  describe 'validations for starts_at and ends_at fields' do
    context 'when both are nil' do
      it 'skips validation' do
        menu = Menu.new(name: 'Test Menu', starts_at: nil, ends_at: nil, restaurant: restaurant)
        expect(menu).to be_valid
      end
    end

    context 'when only starts_at is provided' do
      it 'requires ends_at to be present' do
        menu = Menu.new(name: 'Test Menu', starts_at: 9, ends_at: nil)
        expect(menu).not_to be_valid
        expect(menu.errors[:ends_at]).to include("can't be blank")
      end
    end

    context 'when only ends_at is provided' do
      it 'requires starts_at to be present' do
        menu = Menu.new(name: 'Test Menu', starts_at: nil, ends_at: 17)
        expect(menu).not_to be_valid
        expect(menu.errors[:starts_at]).to include("can't be blank")
      end
    end

    context 'when both are provided, starts_at is before ends_at and is in the range of 0-23' do
      it 'is valid' do
        menu = Menu.new(name: 'Test Menu', starts_at: 9, ends_at: 17, restaurant: restaurant)
        expect(menu).to be_valid
      end
    end
  end

  describe 'hour range validation (0-23)' do
    context 'when both times are present and valid (0-23)' do
      it 'is valid with minimum values' do
        menu = Menu.new(name: 'Test Menu', starts_at: 0, ends_at: 1, restaurant: restaurant)
        expect(menu).to be_valid
      end

      it 'is valid with maximum values' do
        menu = Menu.new(name: 'Test Menu', starts_at: 22, ends_at: 23, restaurant: restaurant)
        expect(menu).to be_valid
      end

      it 'is valid with mid-range values' do
        menu = Menu.new(name: 'Test Menu', starts_at: 9, ends_at: 17, restaurant: restaurant)
        expect(menu).to be_valid
      end
    end

    context 'when starts_at is out of range' do
      it 'is invalid when negative' do
        menu = Menu.new(name: 'Test Menu', starts_at: -1, ends_at: 12)
        expect(menu).not_to be_valid
        expect(menu.errors[:starts_at]).to include('must be a valid hour (0-23)')
      end

      it 'is invalid when greater than 23' do
        menu = Menu.new(name: 'Test Menu', starts_at: 24, ends_at: 12)
        expect(menu).not_to be_valid
        expect(menu.errors[:starts_at]).to include('must be a valid hour (0-23)')
      end
    end

    context 'when ends_at is out of range' do
      it 'is invalid when negative' do
        menu = Menu.new(name: 'Test Menu', starts_at: 9, ends_at: -1)
        expect(menu).not_to be_valid
        expect(menu.errors[:ends_at]).to include('must be a valid hour (0-23)')
      end

      it 'is invalid when greater than 23' do
        menu = Menu.new(name: 'Test Menu', starts_at: 9, ends_at: 25)
        expect(menu).not_to be_valid
        expect(menu.errors[:ends_at]).to include('must be a valid hour (0-23)')
      end
    end

    context 'when both times are out of range' do
      it 'is invalid' do
        menu = Menu.new(name: 'Test Menu', starts_at: -1, ends_at: 25)
        expect(menu).not_to be_valid
        expect(menu.errors[:starts_at]).to include('must be a valid hour (0-23)')
        expect(menu.errors[:ends_at]).to include('must be a valid hour (0-23)')
      end
    end
  end

  describe '#valid_start_time custom validation' do
    context 'when both times are present' do
      it 'is valid when starts_at is before ends_at' do
        menu = Menu.new(name: 'Test Menu', starts_at: 9, ends_at: 17, restaurant: restaurant)
        expect(menu).to be_valid
      end

      it 'is invalid when starts_at equals ends_at' do
        menu = Menu.new(name: 'Test Menu', starts_at: 12, ends_at: 12)
        expect(menu).not_to be_valid
        expect(menu.errors[:base]).to include('Start time must be before end time')
      end

      it 'is invalid when starts_at is after ends_at' do
        menu = Menu.new(name: 'Test Menu', starts_at: 17, ends_at: 9)
        expect(menu).not_to be_valid
        expect(menu.errors[:base]).to include('Start time must be before end time')
      end
    end
  end
end
