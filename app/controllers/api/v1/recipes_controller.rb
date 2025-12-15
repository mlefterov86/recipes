module Api
  module V1
    class RecipesController < ApplicationController
      include Paginatable

      def index
        scope = build_scope
        paginated_recipes = paginate(scope)

        render_collection(
          paginated_recipes,
          serializer: RecipeSerializer,
          meta: pagination_meta(scope.count)
        )
      end

      def show
        recipe = Recipe.includes(:category, :author).find(params[:id])
        render_resource(recipe, serializer: RecipeSerializer, serializer_method: :as_detail_json)
      rescue ActiveRecord::RecordNotFound
        render_error("Recipe not found", status: :not_found)
      end

      private

      def build_scope
        Recipe
          .includes(:category, :author)
          .by_category_id(params[:category_id])
          .by_author_id(params[:author_id])
          .search_title(params[:title])
          .search_ingredient(params[:ingredient])
          .full_text_search(params[:query])
          .sorted_by(params[:sort_by])
      end
    end
  end
end
