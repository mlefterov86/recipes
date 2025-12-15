require 'rails_helper'

RSpec.describe AuthorSerializer do
  let(:author) { create(:author, name: 'Chef John') }

  describe '#as_json' do
    subject(:json) { described_class.new(author).as_json }

    it 'returns author id, name, and recipes_count' do
      expect(json).to eq({
        id: author.id,
        name: 'Chef John',
        recipes_count: 0
      })
    end

    it 'includes all expected attributes' do
      expect(json.keys).to contain_exactly(:id, :name, :recipes_count)
    end

    it 'includes correct recipes_count when author has recipes' do
      create_list(:recipe, 5, author: author)
      expect(json[:recipes_count]).to eq(5)
    end
  end
end
