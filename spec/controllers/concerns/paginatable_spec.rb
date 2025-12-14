require 'rails_helper'

RSpec.describe Paginatable, type: :concern do
  let(:dummy_class) do
    Class.new do
      include Paginatable
      attr_accessor :params

      def initialize(params = {})
        @params = params
      end
    end
  end

  let(:category) { create(:category) }
  let(:author) { create(:author) }
  let!(:recipes) { create_list(:recipe, 25, category: category, author: author) }
  let(:dummy_instance) { dummy_class.new(params) }

  describe '#current_page' do
    context 'when page param is provided' do
      let(:params) { { page: '3' } }

      it 'returns the page number' do
        expect(dummy_instance.current_page).to eq(3)
      end
    end

    context 'when page param is not provided' do
      let(:params) { {} }

      it 'returns 1' do
        expect(dummy_instance.current_page).to eq(1)
      end
    end

    context 'when page param is 0 or negative' do
      it 'returns 1 for zero' do
        instance = dummy_class.new(page: '0')
        expect(instance.current_page).to eq(1)
      end

      it 'returns 1 for negative numbers' do
        instance = dummy_class.new(page: '-5')
        expect(instance.current_page).to eq(1)
      end
    end

    context 'when page param is invalid' do
      let(:params) { { page: 'invalid' } }

      it 'returns 1' do
        expect(dummy_instance.current_page).to eq(1)
      end
    end
  end

  describe '#paginate' do
    let(:scope) { Recipe.all }

    context 'on first page' do
      let(:params) { { page: '1' } }

      it 'returns first 20 records' do
        result = dummy_instance.paginate(scope)
        expect(result.count).to eq(20)
      end
    end

    context 'on second page' do
      let(:params) { { page: '2' } }

      it 'returns remaining 5 records' do
        result = dummy_instance.paginate(scope)
        expect(result.count).to eq(5)
      end
    end

    context 'when no page param' do
      let(:params) { {} }

      it 'defaults to first page' do
        result = dummy_instance.paginate(scope)
        expect(result.count).to eq(20)
      end
    end
  end

  describe '#pagination_meta' do
    context 'with 25 total records and default per_page (20)' do
      let(:params) { { page: '1' } }

      it 'returns correct metadata for first page' do
        meta = dummy_instance.pagination_meta(25)

        expect(meta).to eq({
          current_page: 1,
          per_page: 20,
          total_count: 25,
          total_pages: 2,
          has_next: true,
          has_prev: false
        })
      end
    end

    context 'on last page' do
      let(:params) { { page: '2' } }

      it 'returns correct metadata' do
        meta = dummy_instance.pagination_meta(25)

        expect(meta).to eq({
          current_page: 2,
          per_page: 20,
          total_count: 25,
          total_pages: 2,
          has_next: false,
          has_prev: true
        })
      end
    end

    context 'with exact multiple of per_page' do
      let(:params) { { page: '1' } }

      it 'calculates total_pages correctly' do
        meta = dummy_instance.pagination_meta(20)

        expect(meta[:total_pages]).to eq(1)
        expect(meta[:has_next]).to eq(false)
      end
    end

    context 'with empty result set' do
      let(:params) { { page: '1' } }

      it 'handles zero records' do
        meta = dummy_instance.pagination_meta(0)

        expect(meta).to eq({
          current_page: 1,
          per_page: 20,
          total_count: 0,
          total_pages: 0,
          has_next: false,
          has_prev: false
        })
      end
    end
  end
end
