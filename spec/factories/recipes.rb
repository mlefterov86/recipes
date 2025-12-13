FactoryBot.define do
  factory :recipe do
    title { Faker::Food.dish }
    cook_time { rand(10..120) }
    prep_time { rand(5..60) }
    ingredients { Array.new(rand(3..10)) { Faker::Food.ingredient } }
    ratings { rand(0.0..5.0).round(2) }
    cuisine { Faker::Nation.nationality }
    image_url { Faker::LoremFlickr.image(size: "400x300", search_terms: [ 'food' ]) }

    association :category
    association :author
  end
end
