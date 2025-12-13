FactoryBot.define do
  factory :author do
    sequence(:name) { |n| "#{Faker::Name.name} #{n}" }
    recipes_count { 0 }
    categories_count { 0 }
  end
end
