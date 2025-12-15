FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "#{Faker::Food.dish} #{n}" }
    recipes_count { 0 }
    authors_count { 0 }
  end
end
