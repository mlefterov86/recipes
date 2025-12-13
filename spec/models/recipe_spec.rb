require 'rails_helper'

RSpec.describe Recipe, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:category).optional.counter_cache(true) }
    it { is_expected.to belong_to(:author).optional.counter_cache(true) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:ingredients) }
    it { is_expected.to validate_numericality_of(:ratings).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(5).allow_nil }
    it { is_expected.to validate_numericality_of(:cook_time).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:prep_time).is_greater_than_or_equal_to(0) }

    context 'validations edge cases' do
      describe 'ratings' do
        it 'accepts nil ratings' do
          recipe = build(:recipe, ratings: nil)
          expect(recipe).to be_valid
        end

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
    it { is_expected.to have_db_column(:category_id).of_type(:integer) }
    it { is_expected.to have_db_column(:author_id).of_type(:integer) }
    it { is_expected.to have_db_column(:image_url).of_type(:string) }
    it { is_expected.to have_db_column(:searchable).of_type(:tsvector) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
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
      expect(recipe.searchable).to include('New')
    end

    it 'updates searchable field when cuisine changes' do
      old_searchable = recipe.searchable
      recipe.update!(cuisine: 'Italian')
      expect(recipe.searchable).not_to eq(old_searchable)
      expect(recipe.searchable).to include('Italian')
    end

    it 'updates searchable field when category changes' do
      new_category = create(:category, name: 'Pasta')
      old_searchable = recipe.searchable
      recipe.update!(category: new_category)
      expect(recipe.searchable).not_to eq(old_searchable)
      expect(recipe.searchable).to include('Pasta')
    end

    it 'updates searchable field when author changes' do
      new_author = create(:author, name: 'Gordon Ramsay')
      old_searchable = recipe.searchable
      recipe.update!(author: new_author)
      expect(recipe.searchable).not_to eq(old_searchable)
      expect(recipe.searchable).to include('Gordon')
    end

    it 'updates searchable field when ingredients change' do
      old_searchable = recipe.searchable
      recipe.update!(ingredients: [ 'cheese', 'basil', 'olive oil' ])
      expect(recipe.searchable).not_to eq(old_searchable)
      expect(recipe.searchable).to include('cheese')
    end

    it 'includes title in searchable' do
      expect(recipe.searchable).to include(recipe.title)
    end

    it 'includes category name in searchable' do
      expect(recipe.searchable).to include(recipe.category.name)
    end

    it 'includes author name in searchable' do
      expect(recipe.searchable).to include(recipe.author.name)
    end

    it 'includes cuisine in searchable' do
      expect(recipe.searchable).to include(recipe.cuisine)
    end

    it 'includes ingredients in searchable' do
      expect(recipe.searchable).to include(*recipe.ingredients)
    end

    it 'handles nil cuisine gracefully' do
      recipe = create(:recipe, cuisine: nil, category: category, author: author)
      expect(recipe.searchable).to be_present
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
