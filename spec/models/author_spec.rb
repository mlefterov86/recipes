require 'rails_helper'

RSpec.describe Author, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:recipes).dependent(:nullify) }
    it { is_expected.to have_many(:categories).through(:recipes) }
  end

  describe 'validations' do
    subject { build(:author) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'database columns' do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:recipes_count).of_type(:integer).with_options(default: 0, null: false) }
    it { is_expected.to have_db_column(:categories_count).of_type(:integer).with_options(default: 0, null: false) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe 'indexes' do
    it { is_expected.to have_db_index(:name).unique }
  end

  describe '#refresh_categories_count!' do
    let(:author) { create(:author) }
    let(:category1) { create(:category, name: 'Pizza') }
    let(:category2) { create(:category, name: 'Pasta') }

    before do
      create(:recipe, author: author, category: category1)
      create(:recipe, author: author, category: category2)
      create(:recipe, author: author, category: category1)
      author.update_column(:categories_count, 0)
    end

    it 'updates categories_count to match actual distinct categories' do
      expect { author.refresh_categories_count! }
        .to change { author.reload.categories_count }.from(0).to(2)
    end
  end

  describe 'counter cache for recipes_count' do
    let(:author) { create(:author) }
    let(:category) { create(:category) }

    it 'starts at 0' do
      expect(author.recipes_count).to eq(0)
    end

    it 'increments when recipe is created' do
      expect {
        create(:recipe, author: author, category: category)
      }.to change { author.reload.recipes_count }.from(0).to(1)
    end

    it 'decrements when recipe is destroyed' do
      recipe = create(:recipe, author: author, category: category)
      expect {
        recipe.destroy
      }.to change { author.reload.recipes_count }.from(1).to(0)
    end

    it 'updates when recipe author changes' do
      new_author = create(:author, name: 'New Author')
      recipe = create(:recipe, author: author, category: category)

      expect {
        recipe.update!(author: new_author)
      }.to change { author.reload.recipes_count }.from(1).to(0)
       .and change { new_author.reload.recipes_count }.from(0).to(1)
    end
  end

  describe 'name normalization' do
    it 'strips whitespace from name before saving' do
      author = create(:author, name: '  Chef John  ')
      expect(author.name).to eq('Chef John')
    end

    it 'does not allow duplicate names case insensitively' do
      create(:author, name: 'Chef John')
      duplicate = build(:author, name: 'chef john')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end
  end

  describe 'recipe deletion with nullify dependency' do
    let(:author) { create(:author) }
    let(:category) { create(:category) }
    let!(:recipe) { create(:recipe, author: author, category: category) }

    it 'sets recipe author_id to null when author is destroyed' do
      author.destroy
      expect(recipe.reload.author_id).to be_nil
    end

    it 'does not delete recipes when author is destroyed' do
      expect { author.destroy }.not_to change { Recipe.count }
    end
  end
end
