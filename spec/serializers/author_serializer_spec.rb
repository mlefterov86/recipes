require 'rails_helper'

RSpec.describe AuthorSerializer do
  let(:author) { create(:author, name: 'Chef John') }

  describe '#as_json' do
    subject(:json) { described_class.new(author).as_json }

    it 'returns author id and name' do
      expect(json).to eq({
        id: author.id,
        name: 'Chef John'
      })
    end

    it 'does not include other attributes' do
      expect(json.keys).to contain_exactly(:id, :name)
    end
  end
end
