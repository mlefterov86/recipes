require 'rails_helper'

RSpec.describe CategorySerializer do
  let(:category) { create(:category, name: 'Italian') }

  describe '#as_json' do
    subject(:json) { described_class.new(category).as_json }

    it 'returns category id and name' do
      expect(json).to eq({
        id: category.id,
        name: 'Italian'
      })
    end

    it 'does not include other attributes' do
      expect(json.keys).to contain_exactly(:id, :name)
    end
  end
end
