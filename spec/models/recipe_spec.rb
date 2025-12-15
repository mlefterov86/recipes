require 'rails_helper'

RSpec.describe Recipe, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:category).optional.counter_cache(true) }
    it { is_expected.to belong_to(:author).optional.counter_cache(true) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:ingredients) }
    it { is_expected.to validate_numericality_of(:ratings).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(5) }
    it { is_expected.to validate_numericality_of(:cook_time).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:prep_time).is_greater_than_or_equal_to(0) }

    context 'validations edge cases' do
      describe 'ratings' do
        it 'accepts ratings at minimum boundary (0)' do
          recipe = build(:recipe, ratings: 0)
          expect(recipe).to be_valid
        end

        it 'accepts ratings at maximum boundary (5)' do
          recipe = build(:recipe, ratings: 5)
          expect(recipe).to be_valid
        end

        it 'rejects ratings below 0' do
          recipe = build(:recipe, ratings: -0.1)
          expect(recipe).not_to be_valid
          expect(recipe.errors[:ratings]).to be_present
        end

        it 'rejects ratings above 5' do
          recipe = build(:recipe, ratings: 5.1)
          expect(recipe).not_to be_valid
          expect(recipe.errors[:ratings]).to be_present
        end
      end

      describe 'cook_time' do
        it 'rejects nil cook_time' do
          recipe = build(:recipe, cook_time: nil)
          expect(recipe).not_to be_valid
          expect(recipe.errors[:cook_time]).to be_present
        end

        it 'accepts 0 cook_time' do
          recipe = build(:recipe, cook_time: 0)
          expect(recipe).to be_valid
        end

        it 'rejects negative cook_time' do
          recipe = build(:recipe, cook_time: -1)
          expect(recipe).not_to be_valid
          expect(recipe.errors[:cook_time]).to be_present
        end
      end

      describe 'prep_time' do
        it 'rejects nil prep_time' do
          recipe = build(:recipe, prep_time: nil)
          expect(recipe).not_to be_valid
          expect(recipe.errors[:prep_time]).to be_present
        end

        it 'accepts 0 prep_time' do
          recipe = build(:recipe, prep_time: 0)
          expect(recipe).to be_valid
        end

        it 'rejects negative prep_time' do
          recipe = build(:recipe, prep_time: -1)
          expect(recipe).not_to be_valid
          expect(recipe.errors[:prep_time]).to be_present
        end
      end

      describe 'ingredients' do
        it 'rejects empty ingredients array' do
          recipe = build(:recipe, ingredients: [])
          expect(recipe).not_to be_valid
          expect(recipe.errors[:ingredients]).to be_present
        end

        it 'accepts array with multiple ingredients' do
          recipe = build(:recipe, ingredients: [ 'flour', 'sugar', 'butter' ])
          expect(recipe).to be_valid
        end
      end
    end
  end

  describe 'database columns' do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:cook_time).of_type(:integer) }
    it { is_expected.to have_db_column(:prep_time).of_type(:integer) }
    it { is_expected.to have_db_column(:ingredients).of_type(:jsonb).with_options(null: false) }
    it { is_expected.to have_db_column(:ratings).of_type(:decimal) }
    it { is_expected.to have_db_column(:cuisine).of_type(:string) }
    it { is_expected.to have_db_column(:category_id).of_type(:uuid) }
    it { is_expected.to have_db_column(:author_id).of_type(:uuid) }
    it { is_expected.to have_db_column(:image_url).of_type(:string) }
    it { is_expected.to have_db_column(:searchable).of_type(:tsvector) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe 'scopes' do
    let(:category1) { create(:category, name: 'Pizza') }
    let(:category2) { create(:category, name: 'Pasta') }
    let(:author1) { create(:author, name: 'Chef John') }
    let(:author2) { create(:author, name: 'bluegirl') }

    let!(:recipe1) { create(:recipe, title: 'Margherita Pizza', category: category1, author: author1, ratings: 4.5, created_at: 2.days.ago) }
    let!(:recipe2) { create(:recipe, title: 'Pepperoni Pizza', category: category1, author: author2, ratings: 4.8, created_at: 1.day.ago) }
    let!(:recipe3) { create(:recipe, title: 'Spaghetti Carbonara', category: category2, author: author1, ratings: 4.2, created_at: 3.days.ago) }
    let!(:recipe4) { create(:recipe, title: 'Penne Arrabbiata', category: category2, author: author2, ratings: 4.0, created_at: 4.days.ago) }

    describe '.by_category_id' do
      it 'filters recipes by category_id' do
        results = Recipe.by_category_id(category1.id)
        expect(results).to contain_exactly(recipe1, recipe2)
      end

      it 'returns all recipes when category_id is nil' do
        results = Recipe.by_category_id(nil)
        expect(results.count).to eq(4)
      end

      it 'returns all recipes when category_id is blank string' do
        results = Recipe.by_category_id('')
        expect(results.count).to eq(4)
      end
    end

    describe '.by_author_id' do
      it 'filters recipes by author_id' do
        results = Recipe.by_author_id(author1.id)
        expect(results).to contain_exactly(recipe1, recipe3)
      end

      it 'returns all recipes when author_id is nil' do
        results = Recipe.by_author_id(nil)
        expect(results.count).to eq(4)
      end

      it 'returns all recipes when author_id is blank string' do
        results = Recipe.by_author_id('')
        expect(results.count).to eq(4)
      end
    end

    describe '.search_title' do
      it 'finds recipes with matching title (case-insensitive)' do
        results = Recipe.search_title('pizza')
        expect(results).to contain_exactly(recipe1, recipe2)
      end

      it 'finds recipes with partial title match' do
        results = Recipe.search_title('penne')
        expect(results).to contain_exactly(recipe4)
      end

      it 'is case-insensitive' do
        results = Recipe.search_title('PIZZA')
        expect(results).to contain_exactly(recipe1, recipe2)
      end

      it 'returns all recipes when query is nil' do
        results = Recipe.search_title(nil)
        expect(results.count).to eq(4)
      end

      it 'returns all recipes when query is blank' do
        results = Recipe.search_title('')
        expect(results.count).to eq(4)
      end
    end

    describe '.search_ingredient' do
      let!(:chicken_recipe) { create(:recipe, title: 'Chicken Soup', ingredients: [ 'chicken', 'carrots', 'celery' ]) }
      let!(:beef_recipe) { create(:recipe, title: 'Beef Stew', ingredients: [ 'beef', 'potatoes', 'carrots' ]) }
      let!(:title_only_recipe) { create(:recipe, title: 'Chicken Parmesan', ingredients: [ 'pasta', 'cheese' ]) }

      it 'finds recipes containing the searched ingredient in ingredients array' do
        results = Recipe.search_ingredient('chicken')
        expect(results).to include(chicken_recipe)
        expect(results).not_to include(beef_recipe)
      end

      it 'does not find recipes with the term only in title' do
        results = Recipe.search_ingredient('chicken')
        expect(results).not_to include(title_only_recipe)
      end

      it 'is case insensitive' do
        results = Recipe.search_ingredient('CHICKEN')
        expect(results).to include(chicken_recipe)
      end

      it 'returns all recipes when query is nil' do
        results = Recipe.search_ingredient(nil)
        expect(results.count).to be >= 7
      end

      it 'returns all recipes when query is blank' do
        results = Recipe.search_ingredient('')
        expect(results.count).to be >= 7
      end
    end

    describe '.full_text_search' do
      let!(:chicken_recipe) { create(:recipe, title: 'Chicken Soup', ingredients: [ 'chicken', 'carrots', 'celery' ]) }
      let!(:beef_recipe) { create(:recipe, title: 'Beef Stew', ingredients: [ 'beef', 'potatoes', 'carrots' ]) }
      let!(:title_only_recipe) { create(:recipe, title: 'Chicken Parmesan', ingredients: [ 'pasta', 'cheese' ]) }

      it 'finds recipes with term in ingredients' do
        results = Recipe.full_text_search('chicken')
        expect(results).to include(chicken_recipe)
      end

      it 'finds recipes with term in title' do
        results = Recipe.full_text_search('chicken')
        expect(results).to include(title_only_recipe)
      end

      it 'finds recipes with term in category, author, or cuisine' do
        italian_category = create(:category, name: 'Italian')
        italian_recipe = create(:recipe, title: 'Pasta Dish', ingredients: [ 'pasta' ], category: italian_category)

        results = Recipe.full_text_search('italian')
        expect(results).to include(italian_recipe)
      end

      it 'returns all recipes when query is nil' do
        results = Recipe.full_text_search(nil)
        expect(results.count).to be >= 7
      end

      it 'returns all recipes when query is blank' do
        results = Recipe.full_text_search('')
        expect(results.count).to be >= 7
      end
    end

    describe 'sorting scopes' do
      describe '.sorted_by_rating_desc' do
        it 'sorts recipes by rating descending' do
          results = Recipe.sorted_by_rating_desc.limit(2)
          expect(results.first).to eq(recipe2) # 4.8
          expect(results.second).to eq(recipe1) # 4.5
        end
      end

      describe '.sorted_by_rating_asc' do
        it 'sorts recipes by rating ascending' do
          results = Recipe.sorted_by_rating_asc.limit(2)
          expect(results.first).to eq(recipe4) # 4.0
          expect(results.second).to eq(recipe3) # 4.2
        end
      end

      describe '.sorted_by_created_desc' do
        it 'sorts recipes by created_at descending' do
          results = Recipe.sorted_by_created_desc.limit(2)
          expect(results.first).to eq(recipe2) # 1 day ago
          expect(results.second).to eq(recipe1) # 2 days ago
        end
      end

      describe '.sorted_by_created_asc' do
        it 'sorts recipes by created_at ascending' do
          results = Recipe.sorted_by_created_asc.limit(2)
          expect(results.first).to eq(recipe4) # 4 days ago
          expect(results.second).to eq(recipe3) # 3 days ago
        end
      end

      describe '.sorted_by_title_asc' do
        it 'sorts recipes by title ascending' do
          results = Recipe.sorted_by_title_asc.limit(2)
          expect(results.first.title).to eq('Margherita Pizza')
          expect(results.second.title).to eq('Penne Arrabbiata')
        end
      end

      describe '.sorted_by_title_desc' do
        it 'sorts recipes by title descending' do
          results = Recipe.sorted_by_title_desc.limit(2)
          expect(results.first.title).to eq('Spaghetti Carbonara')
          expect(results.second.title).to eq('Pepperoni Pizza')
        end
      end

      describe '.sorted_by_author_asc' do
        it 'sorts recipes by author name ascending' do
          results = Recipe.sorted_by_author_asc.limit(2)
          expect(results.map(&:author).map(&:name)).to eq([ 'bluegirl', 'bluegirl' ])
        end

        it 'includes recipes without authors (NULLS LAST)' do
          recipe_without_author = create(:recipe, author: nil, category: category1)
          total_count = Recipe.count
          sorted_count = Recipe.sorted_by_author_asc.count
          expect(sorted_count).to eq(total_count)
          # Recipe without author should be included
          expect(Recipe.sorted_by_author_asc.to_a).to include(recipe_without_author)
        end
      end

      describe '.sorted_by_author_desc' do
        it 'sorts recipes by author name descending' do
          results = Recipe.sorted_by_author_desc.limit(2)
          expect(results.map(&:author).map(&:name)).to eq([ 'Chef John', 'Chef John' ])
        end

        it 'includes recipes without authors (NULLS LAST)' do
          recipe_without_author = create(:recipe, author: nil, category: category1)
          total_count = Recipe.count
          sorted_count = Recipe.sorted_by_author_desc.count
          expect(sorted_count).to eq(total_count)
          # Recipe without author should be included
          expect(Recipe.sorted_by_author_desc.to_a).to include(recipe_without_author)
        end
      end

      describe '.sorted_by_category_asc' do
        it 'sorts recipes by category name ascending' do
          results = Recipe.sorted_by_category_asc.limit(2)
          expect(results.map(&:category).map(&:name)).to eq([ 'Pasta', 'Pasta' ])
        end

        it 'includes recipes without categories (NULLS LAST)' do
          recipe_without_category = create(:recipe, category: nil, author: author1)
          total_count = Recipe.count
          sorted_count = Recipe.sorted_by_category_asc.count
          expect(sorted_count).to eq(total_count)
          # Recipe without category should be included
          expect(Recipe.sorted_by_category_asc.to_a).to include(recipe_without_category)
        end
      end

      describe '.sorted_by_category_desc' do
        it 'sorts recipes by category name descending' do
          results = Recipe.sorted_by_category_desc.limit(2)
          expect(results.map(&:category).map(&:name)).to eq([ 'Pizza', 'Pizza' ])
        end

        it 'includes recipes without categories (NULLS LAST)' do
          recipe_without_category = create(:recipe, category: nil, author: author1)
          total_count = Recipe.count
          sorted_count = Recipe.sorted_by_category_desc.count
          expect(sorted_count).to eq(total_count)
          # Recipe without category should be included
          expect(Recipe.sorted_by_category_desc.to_a).to include(recipe_without_category)
        end
      end

      describe '.sorted_by_default' do
        it 'sorts by rating desc then created_at desc' do
          results = Recipe.sorted_by_default.limit(2)
          expect(results.first).to eq(recipe2) # 4.8, 1 day ago
          expect(results.second).to eq(recipe1) # 4.5, 2 days ago
        end

        it 'uses ID as tie-breaker for consistent ordering when rating and created_at are identical' do
          timestamp = 1.day.ago
          recipe_a = create(:recipe, ratings: 4.5, created_at: timestamp, updated_at: timestamp)
          recipe_b = create(:recipe, ratings: 4.5, created_at: timestamp, updated_at: timestamp)
          recipe_c = create(:recipe, ratings: 4.5, created_at: timestamp, updated_at: timestamp)

          # Sort IDs to determine expected order (highest ID first since we sort desc)
          expected_order = [ recipe_a, recipe_b, recipe_c ].sort_by(&:id).reverse

          # Run query multiple times to ensure consistent results
          3.times do
            results = Recipe.where(id: [ recipe_a.id, recipe_b.id, recipe_c.id ]).sorted_by_default
            expect(results.to_a).to eq(expected_order)
          end
        end
      end
    end

    describe '.sorted_by' do
      it 'sorts by rating_desc when given "rating_desc"' do
        results = Recipe.sorted_by('rating_desc').limit(1)
        expect(results.first).to eq(recipe2)
      end

      it 'sorts by rating_asc when given "rating_asc"' do
        results = Recipe.sorted_by('rating_asc').limit(1)
        expect(results.first).to eq(recipe4)
      end

      it 'sorts by created_desc when given "created_desc"' do
        results = Recipe.sorted_by('created_desc').limit(1)
        expect(results.first).to eq(recipe2)
      end

      it 'sorts by created_asc when given "created_asc"' do
        results = Recipe.sorted_by('created_asc').limit(1)
        expect(results.first).to eq(recipe4)
      end

      it 'sorts by title_asc when given "title_asc"' do
        results = Recipe.sorted_by('title_asc').limit(1)
        expect(results.first.title).to eq('Margherita Pizza')
      end

      it 'sorts by title_desc when given "title_desc"' do
        results = Recipe.sorted_by('title_desc').limit(1)
        expect(results.first.title).to eq('Spaghetti Carbonara')
      end

      it 'sorts by author_asc when given "author_asc"' do
        results = Recipe.sorted_by('author_asc').limit(2)
        expect(results.map(&:author).map(&:name).uniq).to eq([ 'bluegirl' ])
      end

      it 'sorts by author_desc when given "author_desc"' do
        results = Recipe.sorted_by('author_desc').limit(2)
        expect(results.map(&:author).map(&:name).uniq).to eq([ 'Chef John' ])
      end

      it 'sorts by category_asc when given "category_asc"' do
        results = Recipe.sorted_by('category_asc').limit(2)
        expect(results.map(&:category).map(&:name).uniq).to eq([ 'Pasta' ])
      end

      it 'sorts by category_desc when given "category_desc"' do
        results = Recipe.sorted_by('category_desc').limit(2)
        expect(results.map(&:category).map(&:name).uniq).to eq([ 'Pizza' ])
      end

      it 'uses default sorting when given nil' do
        results = Recipe.sorted_by(nil).limit(1)
        expect(results.first).to eq(recipe2)
      end

      it 'uses default sorting when given unknown value' do
        results = Recipe.sorted_by('unknown').limit(1)
        expect(results.first).to eq(recipe2)
      end
    end

    describe 'chaining scopes' do
      it 'can chain filter and sort scopes' do
        results = Recipe.by_category_id(category1.id).sorted_by_rating_desc
        expect(results.first).to eq(recipe2) # Pepperoni Pizza, 4.8
        expect(results.second).to eq(recipe1) # Margherita Pizza, 4.5
      end

      it 'can chain multiple filter scopes' do
        results = Recipe.by_category_id(category1.id).by_author_id(author1.id)
        expect(results).to contain_exactly(recipe1)
      end

      it 'can chain all scopes together' do
        results = Recipe.by_category_id(category1.id)
                       .by_author_id(author1.id)
                       .search_title('margherita')
                       .sorted_by('rating_desc')
        expect(results).to contain_exactly(recipe1)
      end
    end
  end

  describe 'counter cache behavior' do
    let(:category) { create(:category) }
    let(:author) { create(:author) }
    let!(:recipe) { create(:recipe, category: category, author: author) }

    describe 'category counter cache' do
      it 'increments category recipes_count when recipe is created' do
        expect {
          create(:recipe, category: category)
        }.to change { category.reload.recipes_count }.from(1).to(2)
      end

      it 'decrements category recipes_count when recipe is destroyed' do
        expect {
          recipe.destroy
        }.to change { category.reload.recipes_count }.from(1).to(0)
      end

      context 'when recipe category changes' do
        let(:new_category) { create(:category, name: 'Desserts') }

        it 'updates both categories' do
          expect {
            recipe.update!(category: new_category)
          }.to change { category.reload.recipes_count }.from(1).to(0)
           .and change { new_category.reload.recipes_count }.from(0).to(1)
        end
      end
    end

    describe 'author counter cache' do
      it 'increments author recipes_count when recipe is created' do
        expect {
          create(:recipe, author: author)
        }.to change { author.reload.recipes_count }.from(1).to(2)
      end

      it 'decrements author recipes_count when recipe is destroyed' do
        expect {
          recipe.destroy
        }.to change { author.reload.recipes_count }.from(1).to(0)
      end

      context 'when recipe author changes' do
        let(:new_author) { create(:author, name: 'Gordon Ramsay') }

        it 'updates both authors' do
          expect {
            recipe.update!(author: new_author)
          }.to change { author.reload.recipes_count }.from(1).to(0)
           .and change { new_author.reload.recipes_count }.from(0).to(1)
        end
      end
    end
  end

  describe 'searchable column update' do
    let!(:recipe) { create(:recipe, category: category, author: author) }
    let(:category) { create(:category, name: 'Pizza') }
    let(:author) { create(:author, name: 'Chef John') }

    it 'populates searchable field on create' do
      expect(recipe.searchable).to be_present
    end

    it 'updates searchable field when title changes' do
      old_searchable = recipe.searchable
      recipe.update!(title: 'New Title')
      expect(recipe.searchable).not_to eq(old_searchable)
      expect(recipe.searchable).to include('new')
    end

    it 'updates searchable field when cuisine changes' do
      old_searchable = recipe.searchable
      recipe.update!(cuisine: 'Italian')
      expect(recipe.searchable).not_to eq(old_searchable)
      expect(recipe.searchable).to include('italian')
    end

    it 'updates searchable field when category changes' do
      new_category = create(:category, name: 'Pasta')
      old_searchable = recipe.searchable
      recipe.update!(category: new_category)
      expect(recipe.searchable).not_to eq(old_searchable)
      expect(recipe.searchable).to include('pasta')
    end

    it 'updates searchable field when author changes' do
      new_author = create(:author, name: 'Gordon Ramsay')
      old_searchable = recipe.searchable
      recipe.update!(author: new_author)
      expect(recipe.searchable).not_to eq(old_searchable)
      expect(recipe.searchable).to include('gordon')
    end

    it 'updates searchable field when ingredients change' do
      old_searchable = recipe.searchable
      recipe.update!(ingredients: [ 'cheese', 'basil', 'olive oil' ])
      expect(recipe.searchable).not_to eq(old_searchable)
      expect(recipe.searchable).to include('chees')  # Stemmed version of 'cheese'
    end

    it 'includes title in searchable' do
      # Check for lowercase version (tsvector normalizes to lowercase and may stem)
      # Check first 4 characters of first word to handle stemming
      first_word = recipe.title.split.first.downcase
      expect(recipe.searchable.downcase).to include(first_word[0..3])
    end

    it 'includes category name in searchable' do
      # Check for lowercase version
      expect(recipe.searchable.downcase).to include(recipe.category.name.downcase)
    end

    it 'includes author name in searchable' do
      # Check for lowercase first name
      expect(recipe.searchable.downcase).to include(recipe.author.name.split.first.downcase)
    end

    it 'includes cuisine in searchable' do
      # Check for first word of cuisine (tsvector tokenizes on word boundaries)
      first_word = recipe.cuisine.split.first.downcase
      # Check first 3 characters to handle stemming
      expect(recipe.searchable.downcase).to include(first_word[0..2])
    end

    it 'includes ingredients in searchable' do
      # Check that at least one ingredient word appears (stemmed/lowercase)
      first_ingredient_word = recipe.ingredients.first.split.first.downcase
      expect(recipe.searchable.downcase).to include(first_ingredient_word[0..2])  # Check first 3 chars to handle stemming
    end

    it 'handles nil cuisine gracefully' do
      recipe = create(:recipe, cuisine: nil, category: category, author: author)
      expect(recipe.searchable).to be_present
    end

    it 'handles special characters in recipe data' do
      special_category = create(:category, name: "Pizza & Pasta")
      special_recipe = create(:recipe,
        title: "Lamb Grinder: ¼ cup kosher salt",
        ingredients: [ "¼ cup salt", "½ cup pepper", "Chef's special sauce" ],
        cuisine: "Chef's Italian",
        category: special_category,
        author: author
      )

      expect(special_recipe.searchable).to be_present
      expect(special_recipe.searchable).to include('lamb')
      expect(special_recipe.searchable).to include('grinder')
      expect(special_recipe.searchable).to include('salt')
    end
  end

  describe 'parent counter updates' do
    let(:category1) { create(:category, name: 'Pizza') }
    let(:category2) { create(:category, name: 'Pasta') }
    let(:author1) { create(:author, name: 'Chef John') }
    let(:author2) { create(:author, name: 'Jamie Oliver') }
    let!(:recipe) { create(:recipe, category: category1, author: author1) }

    context 'when category changes' do
      it 'updates authors_count for both old and new categories' do
        expect { recipe.update!(category: category2) }
          .to change { category1.reload.authors_count }.from(1).to(0)
          .and change { category2.reload.authors_count }.from(0).to(1)
      end
    end

    context 'when author changes' do
      it 'updates categories_count for both old and new authors' do
        expect { recipe.update!(author: author2) }
          .to change { author1.reload.categories_count }.from(1).to(0)
          .and change { author2.reload.categories_count }.from(0).to(1)
      end
    end

    context 'when recipe is destroyed' do
      before do
        category1.update_column(:authors_count, 1)
        author1.update_column(:categories_count, 1)
      end

      it 'updates category authors_count' do
        expect { recipe.destroy }.to change { category1.reload.authors_count }.from(1).to(0)
      end

      it 'updates author categories_count' do
        expect { recipe.destroy }.to change { author1.reload.categories_count }.from(1).to(0)
      end
    end
  end

  describe 'optional associations' do
    it 'allows recipe without category' do
      recipe = build(:recipe, category: nil)
      expect(recipe).to be_valid
    end

    it 'allows recipe without author' do
      recipe = build(:recipe, author: nil)
      expect(recipe).to be_valid
    end

    it 'allows recipe without both category and author' do
      recipe = build(:recipe, category: nil, author: nil)
      expect(recipe).to be_valid
    end
  end
end
