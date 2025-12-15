require 'rails_helper'

RSpec.describe 'Api::V1::Authors', type: :request do
  describe 'GET /api/v1/authors' do
    let!(:author1) { create(:author, name: 'Chef John') }
    let!(:author2) { create(:author, name: 'Gordon Ramsay') }
    let!(:author3) { create(:author, name: 'Jamie Oliver') }
    let(:json) { json_response }

    it 'returns all authors sorted by name' do
      get '/api/v1/authors'

      expect(response).to have_http_status(:ok)

      expect(json[:data].length).to eq(3)
      expect(json[:data].map { |a| a[:name] }).to eq([ 'Chef John', 'Gordon Ramsay', 'Jamie Oliver' ])
    end

    it 'returns correct JSON structure' do
      get '/api/v1/authors'

      author_json = json[:data].first

      expect(author_json).to include(:id, :name, :recipes_count)
      expect(author_json.keys).to contain_exactly(:id, :name, :recipes_count)
    end

    context 'when no authors exist' do
      before { Author.destroy_all }

      it 'returns empty array' do
        get '/api/v1/authors'

        expect(json[:data]).to be_empty
      end
    end

    context 'with category_id filter' do
      let(:category1) { create(:category, name: 'Italian') }
      let(:category2) { create(:category, name: 'Desserts') }

      let!(:recipe1) { create(:recipe, category: category1, author: author1) }
      let!(:recipe2) { create(:recipe, category: category1, author: author2) }
      let!(:recipe3) { create(:recipe, category: category2, author: author3) }

      it 'returns only authors that have recipes in the specified category' do
        get "/api/v1/authors?category_id=#{category1.id}"

        expect(json[:data].length).to eq(2)
        expect(json[:data].map { |a| a[:id] }).to contain_exactly(author1.id, author2.id)
      end

      it 'returns empty array when category has no recipes' do
        category_without_recipes = create(:category, name: 'No Recipes')
        get "/api/v1/authors?category_id=#{category_without_recipes.id}"

        expect(json[:data]).to be_empty
      end

      it 'includes the currently selected author even if they do not match the category filter' do
        get "/api/v1/authors?category_id=#{category1.id}&author_id=#{author3.id}"

        # Should include author3 even though they don't have recipes in category1
        expect(json[:data].map { |a| a[:id] }).to include(author3.id)
        # Should also include authors who do match the filter
        expect(json[:data].map { |a| a[:id] }).to include(author1.id, author2.id)
      end
    end
  end
end
