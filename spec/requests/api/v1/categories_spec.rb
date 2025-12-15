require 'rails_helper'

RSpec.describe 'Api::V1::Categories', type: :request do
  describe 'GET /api/v1/categories' do
    let!(:category1) { create(:category, name: 'Italian') }
    let!(:category2) { create(:category, name: 'Desserts') }
    let!(:category3) { create(:category, name: 'Asian') }
    let(:json) { json_response }

    it 'returns all categories sorted by name' do
      get '/api/v1/categories'

      expect(response).to have_http_status(:ok)

      expect(json[:data].length).to eq(3)
      expect(json[:data].map { |c| c[:name] }).to eq([ 'Asian', 'Desserts', 'Italian' ])
    end

    it 'returns correct JSON structure' do
      get '/api/v1/categories'

      category_json = json[:data].first

      expect(category_json).to include(:id, :name, :recipes_count)
      expect(category_json.keys).to contain_exactly(:id, :name, :recipes_count)
    end

    context 'when no categories exist' do
      before { Category.destroy_all }

      it 'returns empty array' do
        get '/api/v1/categories'

        expect(json[:data]).to be_empty
      end
    end

    context 'with author_id filter' do
      let(:author1) { create(:author, name: 'Chef John') }
      let(:author2) { create(:author, name: 'Gordon Ramsay') }

      let!(:recipe1) { create(:recipe, category: category1, author: author1) }
      let!(:recipe2) { create(:recipe, category: category2, author: author1) }
      let!(:recipe3) { create(:recipe, category: category3, author: author2) }

      it 'returns only categories that have recipes by the specified author' do
        get "/api/v1/categories?author_id=#{author1.id}"

        expect(json[:data].length).to eq(2)
        expect(json[:data].map { |c| c[:id] }).to contain_exactly(category1.id, category2.id)
      end

      it 'returns empty array when author has no recipes' do
        author_without_recipes = create(:author, name: 'No Recipes')
        get "/api/v1/categories?author_id=#{author_without_recipes.id}"

        expect(json[:data]).to be_empty
      end

      it 'includes the currently selected category even if it does not match the author filter' do
        get "/api/v1/categories?author_id=#{author1.id}&category_id=#{category3.id}"

        # Should include category3 even though author1 doesn't have recipes in it
        expect(json[:data].map { |c| c[:id] }).to include(category3.id)
        # Should also include categories that do match the filter
        expect(json[:data].map { |c| c[:id] }).to include(category1.id, category2.id)
      end
    end
  end
end
