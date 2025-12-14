class Recipe < ApplicationRecord
  belongs_to :category, optional: true, counter_cache: true
  belongs_to :author, optional: true, counter_cache: true

  validates :title, presence: true
  validates :ingredients, presence: true
  validates :ratings, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :cook_time, numericality: { greater_than_or_equal_to: 0 }
  validates :prep_time, numericality: { greater_than_or_equal_to: 0 }

  after_save :update_searchable_tsvector
  after_commit :update_parent_counters, on: [ :create, :update ]
  after_destroy :decrement_parent_counters

  # === Scopes for filtering ===
  scope :by_category_id, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :by_author_id, ->(author_id) { where(author_id: author_id) if author_id.present? }
  scope :search_title, ->(query) { where("title ILIKE ?", "%#{sanitize_sql_like(query)}%") if query.present? }
  scope :search_ingredient, ->(query) { where("EXISTS (SELECT 1 FROM jsonb_array_elements_text(ingredients) AS ingredient WHERE ingredient ILIKE ?)", "%#{sanitize_sql_like(query)}%") if query.present? }
  scope :full_text_search, ->(query) { where("searchable @@ plainto_tsquery('english', ?)", query) if query.present? }

  # === Scopes for sorting ===
  scope :sorted_by_rating_desc, -> { order(ratings: :desc, id: :desc) }
  scope :sorted_by_rating_asc, -> { order(ratings: :asc, id: :asc) }
  scope :sorted_by_created_desc, -> { order(created_at: :desc) }
  scope :sorted_by_created_asc, -> { order(created_at: :asc) }
  scope :sorted_by_title_asc, -> { order(title: :asc) }
  scope :sorted_by_title_desc, -> { order(title: :desc) }
  scope :sorted_by_author_asc, -> { left_joins(:author).order("authors.name ASC NULLS LAST") }
  scope :sorted_by_author_desc, -> { left_joins(:author).order("authors.name DESC NULLS LAST") }
  scope :sorted_by_category_asc, -> { left_joins(:category).order("categories.name ASC NULLS LAST") }
  scope :sorted_by_category_desc, -> { left_joins(:category).order("categories.name DESC NULLS LAST") }
  scope :sorted_by_default, -> { order(ratings: :desc, created_at: :desc) }

  # Dynamic sorting scope
  scope :sorted_by, ->(sort_option) {
    case sort_option
    when "rating_desc"
      sorted_by_rating_desc
    when "rating_asc"
      sorted_by_rating_asc
    when "created_desc"
      sorted_by_created_desc
    when "created_asc"
      sorted_by_created_asc
    when "title_asc"
      sorted_by_title_asc
    when "title_desc"
      sorted_by_title_desc
    when "author_asc"
      sorted_by_author_asc
    when "author_desc"
      sorted_by_author_desc
    when "category_asc"
      sorted_by_category_asc
    when "category_desc"
      sorted_by_category_desc
    else
      sorted_by_default
    end
  }

  private

  # Update tsvector column for full-text search
  def update_searchable_tsvector
    searchable_text = [
      title,
      category&.name,
      author&.name,
      ingredients&.join(" "),
      cuisine
    ].compact.join(" ")

    # Clean the text to remove problematic characters for tsvector
    # Replace special chars that break tsvector parsing with spaces
    cleaned_text = searchable_text.gsub(/[^\w\s-]/, " ").squeeze(" ").strip

    # Execute raw SQL to update the tsvector column
    self.class.connection.execute(
      "UPDATE recipes SET searchable = to_tsvector('english', #{self.class.connection.quote(cleaned_text)}) WHERE id = #{id}"
    )

    # Reload the searchable attribute so it's available in tests
    reload_searchable
  end

  def reload_searchable
    self.searchable = self.class.connection.select_value(
      "SELECT searchable FROM recipes WHERE id = #{id}"
    )
  end

  # Update distinct counter caches when recipe is created or category/author changes
  def update_parent_counters
    return unless saved_change_to_category_id? || saved_change_to_author_id?

    # Update old category's authors_count if category changed
    update_categories_count if saved_change_to_category_id?

    # Update old author's categories_count if author changed
    update_authors_count if saved_change_to_author_id?
  end

  def update_categories_count
    old_category_id = saved_change_to_category_id[0]
    Category.find(old_category_id).refresh_authors_count! if old_category_id.present?
    category&.refresh_authors_count!
  end

  def update_authors_count
    old_author_id = saved_change_to_author_id[0]
    Author.find(old_author_id).refresh_categories_count! if old_author_id.present?
    author&.refresh_categories_count!
  end

  # Decrement distinct counters when recipe is destroyed
  def decrement_parent_counters
    category&.refresh_authors_count!
    author&.refresh_categories_count!
  end
end
