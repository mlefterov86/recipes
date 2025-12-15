require 'rails_helper'

RSpec.describe CategorySerializer do
  let(:category) { create(:category, name: 'Italian') }

  describe '#as_json' do
    subject(:json) { described_class.new(category).as_json }

    it 'returns category id, name, and recipes_count' do
      expect(json).to eq({
        id: category.id,
        name: 'Italian',
        recipes_count: 0
      })
    end

    it 'includes all expected attributes' do
      expect(json.keys).to contain_exactly(:id, :name, :recipes_count)
    end

    it 'includes correct recipes_count when category has recipes' do
      create_list(:recipe, 3, category: category)
      expect(json[:recipes_count]).to eq(3)
    end
  end
end
