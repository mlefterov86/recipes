require 'rails_helper'

RSpec.describe RecipeSerializer do
  let(:category) { create(:category, name: 'Italian') }
  let(:author) { create(:author, name: 'Chef John') }
  let(:recipe) do
    create(:recipe,
      title: 'Pasta Carbonara',
      image_url: 'https://example.com/pasta.jpg',
      ratings: 4.5,
      cook_time: 20,
      prep_time: 10,
      cuisine: 'Italian',
      ingredients: [ 'pasta', 'eggs', 'bacon', 'parmesan' ],
      category: category,
      author: author
    )
  end

  describe '#as_json' do
    subject(:json) { described_class.new(recipe).as_json }

    it 'returns recipe with basic fields' do
      expect(json).to include(
        id: recipe.id,
        title: 'Pasta Carbonara',
        image_url: 'https://example.com/pasta.jpg',
        ratings: 4.5,
        cook_time: 20,
        prep_time: 10,
        cuisine: 'Italian'
      )
    end

    it 'includes serialized category' do
      expect(json[:category]).to eq({ id: category.id, name: 'Italian', recipes_count: 1 })
    end

    it 'includes serialized author' do
      expect(json[:author]).to eq({ id: author.id, name: 'Chef John', recipes_count: 1 })
    end

    it 'includes ingredients array' do
      expect(json[:ingredients]).to eq([ 'pasta', 'eggs', 'bacon', 'parmesan' ])
    end

    it 'does not include created_at' do
      expect(json).not_to have_key(:created_at)
    end

    context 'when recipe has no category' do
      let(:recipe) { create(:recipe, category: nil) }

      it 'returns nil for category' do
        expect(json[:category]).to be_nil
      end
    end

    context 'when recipe has no author' do
      let(:recipe) { create(:recipe, author: nil) }

      it 'returns nil for author' do
        expect(json[:author]).to be_nil
      end
    end

    context 'when recipe has default ratings' do
      let(:recipe) { create(:recipe, ratings: 0.0) }

      it 'returns 0.0 for ratings' do
        expect(json[:ratings]).to eq(0.0)
      end
    end

    it 'returns ratings as a Float, not a string' do
      expect(json[:ratings]).to be_a(Float)
      expect(json[:ratings]).to eq(4.5)
    end
  end

  describe '#as_detail_json' do
    subject(:json) { described_class.new(recipe).as_detail_json }

    it 'includes all fields from as_json' do
      expect(json).to include(
        id: recipe.id,
        title: 'Pasta Carbonara',
        ratings: 4.5
      )
    end

    it 'includes ingredients array' do
      expect(json[:ingredients]).to eq([ 'pasta', 'eggs', 'bacon', 'parmesan' ])
    end

    it 'includes created_at timestamp' do
      expect(json[:created_at]).to eq(recipe.created_at)
    end

    it 'includes nested category' do
      expect(json[:category]).to eq({ id: category.id, name: 'Italian', recipes_count: 1 })
    end

    it 'includes nested author' do
      expect(json[:author]).to eq({ id: author.id, name: 'Chef John', recipes_count: 1 })
    end
  end
end
