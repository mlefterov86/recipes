module Api
  module V1
    class AuthorsController < ApplicationController
      def index
        # Convert to array to manipulate the results
        authors_array = authors.to_a

        # Always include the currently selected author if author_id is provided
        # This ensures the selected value shows in the dropdown even when filtered
        if params[:author_id].present?
          if author && !authors_array.any? { |a| a.id == author.id }
            authors_array << author
            authors_array.sort_by!(&:name)
          end
        end

        render_collection(authors_array, serializer: AuthorSerializer)
      end

      private

      def author
        @author ||= Author.find_by(id: params[:author_id])
      end

      def authors
        @authors ||= Author.order(:name).by_category(params[:category_id])
      end
    end
  end
end
