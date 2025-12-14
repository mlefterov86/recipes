module Api
  module V1
    class CategoriesController < ApplicationController
      def index
        # Convert to array to manipulate the results
        categories_array = categories.to_a

        # Always include the currently selected category if category_id is provided
        # This ensures the selected value shows in the dropdown even when filtered
        if params[:category_id].present?
          if category && !categories_array.any? { |c| c.id == category.id }
            categories_array << category
            categories_array.sort_by!(&:name)
          end
        end

        render_collection(categories_array, serializer: CategorySerializer)
      end

      private

      def category
        @category ||= Category.find_by(id: params[:category_id])
      end

      def categories
        @categories ||= Category.order(:name).by_author(params[:author_id])
      end
    end
  end
end
