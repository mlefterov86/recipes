require 'rails_helper'

RSpec.describe 'Api::V1::Recipes', type: :request do
  let!(:category_italian) { create(:category, name: 'Italian') }
  let!(:category_desserts) { create(:category, name: 'Desserts') }
  let!(:author_john) { create(:author, name: 'Chef John') }
  let!(:author_gordon) { create(:author, name: 'Gordon Ramsay') }
  let(:json) { json_response }

  describe 'GET /api/v1/recipes' do
    context 'without any filters' do
      let!(:recipe1) { create(:recipe, title: 'Pasta', ratings: 4.5, category: category_italian, author: author_john, created_at: 2.days.ago) }
      let!(:recipe2) { create(:recipe, title: 'Pizza', ratings: 5.0, category: category_italian, author: author_gordon, created_at: 1.day.ago) }
      let!(:recipe3) { create(:recipe, title: 'Cake', ratings: 3.5, category: category_desserts, author: author_john, created_at: 3.days.ago) }

      it 'returns all recipes with default sorting (rating desc, then created_at desc)' do
        get '/api/v1/recipes'

        expect(response).to have_http_status(:ok)

        expect(json[:data].length).to eq(3)
        expect(json[:data][0][:id]).to eq(recipe2.id) # 5.0 rating, newest
        expect(json[:data][1][:id]).to eq(recipe1.id) # 4.5 rating
        expect(json[:data][2][:id]).to eq(recipe3.id) # 3.5 rating
      end

      it 'returns correct JSON structure for recipes' do
        get '/api/v1/recipes'

        recipe_json = json[:data].first

        expect(recipe_json).to include(
          :id, :title, :image_url, :ratings, :cook_time, :prep_time, :cuisine, :category, :author, :ingredients
        )
        expect(recipe_json[:category]).to include(:id, :name)
        expect(recipe_json[:author]).to include(:id, :name)
      end

      it 'returns ratings as a numeric value, not a string' do
        get '/api/v1/recipes'

        recipe_with_rating = json[:data].find { |r| r[:id] == recipe1.id }

        expect(recipe_with_rating[:ratings]).to be_a(Numeric)
        expect(recipe_with_rating[:ratings]).to eq(4.5)
      end

      it 'returns pagination metadata' do
        get '/api/v1/recipes'

        expect(json[:meta]).to include(
          current_page: 1,
          per_page: 20,
          total_count: 3,
          total_pages: 1,
          has_next: false,
          has_prev: false
        )
      end
    end

    context 'with category filter' do
      let!(:recipe1) { create(:recipe, title: 'Pasta', category: category_italian, author: author_john) }
      let!(:recipe2) { create(:recipe, title: 'Pizza', category: category_italian, author: author_gordon) }
      let!(:recipe3) { create(:recipe, title: 'Cake', category: category_desserts, author: author_john) }

      it 'returns only recipes from specified category' do
        get "/api/v1/recipes?category_id=#{category_italian.id}"

        expect(json[:data].length).to eq(2)
        expect(json[:data].map { |r| r[:id] }).to contain_exactly(recipe1.id, recipe2.id)
      end
    end

    context 'with author filter' do
      let!(:recipe1) { create(:recipe, title: 'Pasta', category: category_italian, author: author_john) }
      let!(:recipe2) { create(:recipe, title: 'Pizza', category: category_italian, author: author_gordon) }
      let!(:recipe3) { create(:recipe, title: 'Cake', category: category_desserts, author: author_john) }

      it 'returns only recipes from specified author' do
        get "/api/v1/recipes?author_id=#{author_john.id}"

        expect(json[:data].length).to eq(2)
        expect(json[:data].map { |r| r[:id] }).to contain_exactly(recipe1.id, recipe3.id)
      end
    end

    context 'with ingredient search' do
      let!(:recipe1) { create(:recipe, title: 'Pasta Carbonara', ingredients: [ 'pasta', 'eggs', 'bacon' ], category: category_italian, author: author_john) }
      let!(:recipe2) { create(:recipe, title: 'Vegetable Pizza', ingredients: [ 'dough', 'tomato', 'cheese' ], category: category_italian, author: author_gordon) }
      let!(:recipe3) { create(:recipe, title: 'Bacon Cake', ingredients: [ 'flour', 'sugar', 'bacon' ], category: category_desserts, author: author_john) }

      it 'returns recipes containing the searched ingredient in ingredients array' do
        get '/api/v1/recipes?ingredient=bacon'

        expect(json[:data].length).to eq(2)
        expect(json[:data].map { |r| r[:id] }).to contain_exactly(recipe1.id, recipe3.id)
      end

      it 'is case insensitive' do
        get '/api/v1/recipes?ingredient=BACON'

        expect(json[:data].length).to eq(2)
        expect(json[:data].map { |r| r[:id] }).to contain_exactly(recipe1.id, recipe3.id)
      end
    end

    context 'with full-text search (query parameter)' do
      let!(:recipe1) { create(:recipe, title: 'Pasta Carbonara', ingredients: [ 'pasta', 'eggs', 'bacon' ], category: category_italian, author: author_john) }
      let!(:recipe2) { create(:recipe, title: 'Vegetable Pizza', ingredients: [ 'dough', 'tomato', 'cheese' ], category: category_italian, author: author_gordon) }
      let!(:recipe3) { create(:recipe, title: 'Bacon Cake', ingredients: [ 'flour', 'sugar', 'bacon' ], category: category_desserts, author: author_john) }

      it 'searches across all fields including title' do
        get '/api/v1/recipes?query=vegetable'

        expect(json[:data].length).to eq(1)
        expect(json[:data].first[:id]).to eq(recipe2.id)
      end

      it 'searches across all fields including ingredients' do
        get '/api/v1/recipes?query=bacon'

        expect(json[:data].length).to eq(2)
        expect(json[:data].map { |r| r[:id] }).to contain_exactly(recipe1.id, recipe3.id)
      end

      it 'searches across all fields including category name' do
        get '/api/v1/recipes?query=italian'

        expect(json[:data].length).to eq(2)
        expect(json[:data].map { |r| r[:id] }).to contain_exactly(recipe1.id, recipe2.id)
      end
    end

    context 'with multiple filters (AND logic)' do
      let!(:recipe1) { create(:recipe, title: 'Italian Bacon Pasta', ingredients: [ 'pasta', 'bacon' ], category: category_italian, author: author_john) }
      let!(:recipe2) { create(:recipe, title: 'Italian Cheese Pizza', ingredients: [ 'dough', 'cheese' ], category: category_italian, author: author_gordon) }
      let!(:recipe3) { create(:recipe, title: 'Bacon Dessert', ingredients: [ 'flour', 'bacon' ], category: category_desserts, author: author_john) }

      it 'combines category, author, and ingredient filters with AND logic' do
        get "/api/v1/recipes?category_id=#{category_italian.id}&author_id=#{author_john.id}&ingredient=bacon"

        # Only recipe1 matches all three filters
        expect(json[:data].length).to eq(1)
        expect(json[:data].first[:id]).to eq(recipe1.id)
      end

      it 'returns empty array when no recipes match all filters' do
        get "/api/v1/recipes?category_id=#{category_desserts.id}&author_id=#{author_gordon.id}"

        expect(json[:data]).to eq([])
        expect(json[:meta][:total_count]).to eq(0)
      end

      it 'combines category filter with full-text search (query parameter) using AND logic' do
        get "/api/v1/recipes?category_id=#{category_italian.id}&query=bacon"

        # Only recipe1 is in Italian category AND has "bacon" in searchable fields
        expect(json[:data].length).to eq(1)
        expect(json[:data].first[:id]).to eq(recipe1.id)
      end

      it 'combines author filter with full-text search (query parameter) using AND logic' do
        get "/api/v1/recipes?author_id=#{author_john.id}&query=italian"

        # Only recipe1 is by author_john AND has "italian" in searchable fields
        expect(json[:data].length).to eq(1)
        expect(json[:data].first[:id]).to eq(recipe1.id)
      end
    end

    context 'with sorting' do
      let!(:recipe1) { create(:recipe, title: 'Pasta', ratings: 4.5, created_at: 2.days.ago) }
      let!(:recipe2) { create(:recipe, title: 'Pizza', ratings: 5.0, created_at: 1.day.ago) }
      let!(:recipe3) { create(:recipe, title: 'Cake', ratings: 3.5, created_at: 3.days.ago) }

      it 'sorts by rating descending' do
        get '/api/v1/recipes?sort_by=rating_desc'

        expect(json[:data].map { |r| r[:id] }).to eq([ recipe2.id, recipe1.id, recipe3.id ])
      end

      it 'sorts by rating ascending' do
        get '/api/v1/recipes?sort_by=rating_asc'

        expect(json[:data].map { |r| r[:id] }).to eq([ recipe3.id, recipe1.id, recipe2.id ])
      end

      it 'sorts by created_at descending' do
        get '/api/v1/recipes?sort_by=created_desc'

        expect(json[:data].map { |r| r[:id] }).to eq([ recipe2.id, recipe1.id, recipe3.id ])
      end

      it 'sorts by title ascending' do
        get '/api/v1/recipes?sort_by=title_asc'

        expect(json[:data].map { |r| r[:title] }).to eq([ 'Cake', 'Pasta', 'Pizza' ])
      end
    end

    context 'with pagination' do
      before do
        # Create 25 recipes
        25.times do |i|
          create(:recipe, title: "Recipe #{i}", ratings: 5.0 - (i * 0.1))
        end
      end

      it 'returns first page with 20 recipes' do
        get '/api/v1/recipes?page=1'

        expect(json[:data].length).to eq(20)
        expect(json[:meta]).to include(
          current_page: 1,
          per_page: 20,
          total_count: 25,
          total_pages: 2,
          has_next: true,
          has_prev: false
        )
      end

      it 'returns second page with remaining recipes' do
        get '/api/v1/recipes?page=2'

        expect(json[:data].length).to eq(5)
        expect(json[:meta]).to include(
          current_page: 2,
          per_page: 20,
          total_count: 25,
          total_pages: 2,
          has_next: false,
          has_prev: true
        )
      end

      it 'defaults to page 1 when page is not specified' do
        get '/api/v1/recipes'

        expect(json[:meta][:current_page]).to eq(1)
      end

      it 'defaults to page 1 when invalid page is specified' do
        get '/api/v1/recipes?page=0'

        expect(json[:meta][:current_page]).to eq(1)
      end

      it 'accepts custom per_page parameter' do
        get '/api/v1/recipes?per_page=10'

        expect(json[:data].length).to eq(10)
        expect(json[:meta]).to include(
          current_page: 1,
          per_page: 10,
          total_count: 25,
          total_pages: 3,
          has_next: true,
          has_prev: false
        )
      end

      it 'can fetch all recipes with high per_page value' do
        get '/api/v1/recipes?per_page=10000'

        expect(json[:data].length).to eq(25)
        expect(json[:meta]).to include(
          current_page: 1,
          per_page: 10000,
          total_count: 25,
          total_pages: 1,
          has_next: false,
          has_prev: false
        )
      end

      it 'caps per_page at MAX_PER_PAGE (10000)' do
        get '/api/v1/recipes?per_page=999999'

        expect(json[:meta][:per_page]).to eq(10000)
      end

      it 'defaults to 20 per_page when invalid value is provided' do
        get '/api/v1/recipes?per_page=0'

        expect(json[:meta][:per_page]).to eq(20)
      end
    end

    context 'with pagination ordering consistency' do
      before do
        # Create 5 recipes with identical ratings to test ID tie-breaker
        # When ratings are identical, ID should be used for consistent ordering
        5.times do |i|
          create(:recipe,
            title: "Recipe #{i}",
            ratings: 4.5
          )
        end
      end

      it 'returns the same results when requesting page 1 multiple times' do
        get '/api/v1/recipes', params: { page: 1, per_page: 2 }
        first_request_ids = json[:data].map { |r| r[:id] }

        get '/api/v1/recipes', params: { page: 1, per_page: 2 }
        second_request_ids = json[:data].map { |r| r[:id] }

        expect(second_request_ids).to eq(first_request_ids)
      end

      it 'returns the same results when requesting page 2 multiple times' do
        get '/api/v1/recipes', params: { page: 2, per_page: 2 }
        first_request_ids = json[:data].map { |r| r[:id] }

        get '/api/v1/recipes', params: { page: 2, per_page: 2 }
        second_request_ids = json[:data].map { |r| r[:id] }

        expect(second_request_ids).to eq(first_request_ids)
      end

      it 'page 1 returns the expected first 2 recipes sorted by ID desc' do
        # Calculate expected IDs for page 1 (LIMIT 2 OFFSET 0)
        expected_ids = Recipe.sorted_by_default.limit(2).offset(0).pluck(:id)

        get '/api/v1/recipes?page=1&per_page=2'

        expect(json[:meta][:current_page]).to eq(1)
        expect(json[:data].length).to eq(2)
        actual_ids = json[:data].map { |r| r[:id] }
        expect(actual_ids).to eq(expected_ids)
      end

      it 'page 2 returns the expected next 2 recipes sorted by ID desc' do
        # Calculate expected IDs for page 2 (LIMIT 2 OFFSET 2)
        expected_ids = Recipe.sorted_by_default.limit(2).offset(2).pluck(:id)

        get '/api/v1/recipes?page=2&per_page=2'

        expect(json[:meta][:current_page]).to eq(2)
        expect(json[:data].length).to eq(2)
        actual_ids = json[:data].map { |r| r[:id] }
        expect(actual_ids).to eq(expected_ids)
      end

      it 'page 3 returns the expected last recipe sorted by ID desc' do
        # Calculate expected IDs for page 3 (LIMIT 2 OFFSET 4, but only 1 recipe left)
        expected_ids = Recipe.sorted_by_default.limit(2).offset(4).pluck(:id)

        get '/api/v1/recipes?page=3&per_page=2'

        expect(json[:meta][:current_page]).to eq(3)
        expect(json[:data].length).to eq(1)
        actual_ids = json[:data].map { |r| r[:id] }
        expect(actual_ids).to eq(expected_ids)
      end
    end

    context 'with recipes without associations' do
      let!(:recipe) { create(:recipe, category: nil, author: nil) }

      it 'returns recipe with nil category and author' do
        get '/api/v1/recipes'

        expect(json[:data].first[:category]).to be_nil
        expect(json[:data].first[:author]).to be_nil
      end
    end

    context 'with recipes with default ratings' do
      let!(:recipe) { create(:recipe, ratings: 0.0, category: category_italian, author: author_john) }

      it 'returns recipe with 0.0 ratings' do
        get '/api/v1/recipes'

        expect(json[:data].first[:ratings]).to eq(0.0)
      end
    end
  end

  describe 'GET /api/v1/recipes/:id' do
    let!(:recipe) do
      create(:recipe,
        title: 'Pasta Carbonara',
        ingredients: [ 'pasta', 'eggs', 'bacon', 'parmesan' ],
        category: category_italian,
        author: author_john
      )
    end

    it 'returns recipe detail with all fields' do
      get "/api/v1/recipes/#{recipe.id}"

      expect(response).to have_http_status(:ok)
      expect(json[:data]).to include(
        id: recipe.id,
        title: 'Pasta Carbonara',
        ingredients: [ 'pasta', 'eggs', 'bacon', 'parmesan' ]
      )
      expect(json[:data]).to have_key(:created_at)
    end

    it 'includes nested category and author' do
      get "/api/v1/recipes/#{recipe.id}"

      expect(json[:data][:category]).to include(id: category_italian.id, name: 'Italian')
      expect(json[:data][:author]).to include(id: author_john.id, name: 'Chef John')
    end

    it 'returns ratings as a numeric value, not a string' do
      recipe_with_rating = create(:recipe, ratings: 4.75, category: category_italian, author: author_john)
      get "/api/v1/recipes/#{recipe_with_rating.id}"

      expect(json[:data][:ratings]).to be_a(Numeric)
      expect(json[:data][:ratings]).to eq(4.75)
    end

    it 'returns 404 when recipe not found' do
      get '/api/v1/recipes/99999'

      expect(response).to have_http_status(:not_found)
      expect(json[:error][:message]).to eq('Recipe not found')
    end

    context 'when recipe has no category or author' do
      let!(:recipe) { create(:recipe, category: nil, author: nil) }

      it 'returns recipe with nil associations' do
        get "/api/v1/recipes/#{recipe.id}"

        expect(json[:data][:category]).to be_nil
        expect(json[:data][:author]).to be_nil
      end
    end
  end
end
