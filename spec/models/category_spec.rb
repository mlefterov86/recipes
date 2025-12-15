require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:recipes).dependent(:nullify) }
    it { is_expected.to have_many(:authors).through(:recipes) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    context 'with name normalization' do
      it 'enforces uniqueness regardless of case due to normalization' do
        create(:category, name: 'pasta')
        duplicate = build(:category, name: 'PASTA')

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include('has already been taken')
      end
    end
  end

  describe 'database columns' do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:recipes_count).of_type(:integer).with_options(default: 0, null: false) }
    it { is_expected.to have_db_column(:authors_count).of_type(:integer).with_options(default: 0, null: false) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe 'indexes' do
    it { is_expected.to have_db_index(:name).unique }
  end

  describe '#refresh_authors_count!' do
    let(:category) { create(:category) }
    let(:author1) { create(:author, name: 'Chef John') }
    let(:author2) { create(:author, name: 'Jamie Oliver') }

    before do
      create(:recipe, category: category, author: author1)
      create(:recipe, category: category, author: author2)
      create(:recipe, category: category, author: author1)
      category.update_column(:authors_count, 0)
    end

    it 'updates authors_count to match actual distinct authors' do
      expect { category.refresh_authors_count! }
        .to change { category.reload.authors_count }.from(0).to(2)
    end
  end

  describe 'counter cache for recipes_count' do
    let(:category) { create(:category) }
    let(:author) { create(:author) }

    it 'starts at 0' do
      expect(category.recipes_count).to eq(0)
    end

    it 'increments when recipe is created' do
      expect {
        create(:recipe, category: category, author: author)
      }.to change { category.reload.recipes_count }.from(0).to(1)
    end

    it 'decrements when recipe is destroyed' do
      recipe = create(:recipe, category: category, author: author)
      expect {
        recipe.destroy
      }.to change { category.reload.recipes_count }.from(1).to(0)
    end

    it 'updates when recipe category changes' do
      new_category = create(:category, name: 'Desserts')
      recipe = create(:recipe, category: category, author: author)

      expect {
        recipe.update!(category: new_category)
      }.to change { category.reload.recipes_count }.from(1).to(0)
       .and change { new_category.reload.recipes_count }.from(0).to(1)
    end
  end

  describe 'name normalization' do
    it 'strips whitespace and titleizes name before saving' do
      category = create(:category, name: '  cornbread  ')
      expect(category.name).to eq('Cornbread')
    end

    it 'titleizes lowercase names' do
      category = create(:category, name: 'pizza')
      expect(category.name).to eq('Pizza')
    end

    it 'titleizes multiple words' do
      category = create(:category, name: 'chocolate chip cookies')
      expect(category.name).to eq('Chocolate Chip Cookies')
    end

    it 'does not allow duplicate names case insensitively' do
      create(:category, name: 'Pizza')
      duplicate = build(:category, name: 'pizza')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end
  end
end
