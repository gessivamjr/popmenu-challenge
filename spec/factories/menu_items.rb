FactoryBot.define do
  factory :menu_item do
    sequence(:name) { |n| "Menu Item #{n}" }

    transient do
      menu { nil }
    end

    trait :with_menu do
      after(:create) do |menu_item, evaluator|
        menu = evaluator.menu || create(:menu)
        create(:menu_menu_item, menu: menu, menu_item: menu_item)
      end
    end
  end
end
