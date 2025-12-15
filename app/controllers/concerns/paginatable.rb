module Paginatable
  extend ActiveSupport::Concern

  PER_PAGE = 20.freeze
  MAX_PER_PAGE = 10000.freeze

  # Returns the current page number from params, defaulting to 1
  def current_page
    page = params[:page].to_i
    page < 1 ? 1 : page
  end

  # Returns the per_page value from params, defaulting to PER_PAGE
  # Caps at MAX_PER_PAGE to prevent abuse
  def per_page
    per_page_param = params[:per_page].to_i
    return PER_PAGE if per_page_param < 1
    [ per_page_param, MAX_PER_PAGE ].min
  end

  # Paginates the given scope
  # @param scope [ActiveRecord::Relation] The scope to paginate
  # @return [ActiveRecord::Relation] The paginated scope
  def paginate(scope)
    scope.limit(per_page).offset((current_page - 1) * per_page)
  end

  # Generates pagination metadata
  # @param total_count [Integer] The total count of records
  # @return [Hash] Pagination metadata
  def pagination_meta(total_count)
    total_pages = (total_count.to_f / per_page).ceil

    {
      current_page: current_page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages,
      has_next: current_page < total_pages,
      has_prev: current_page > 1
    }
  end
end
