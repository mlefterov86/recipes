class Recipe < ApplicationRecord
  belongs_to :category, optional: true, counter_cache: true
  belongs_to :author, optional: true, counter_cache: true

  validates :title, presence: true
  validates :ingredients, presence: true
  validates :ratings, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :cook_time, numericality: { greater_than_or_equal_to: 0 }
  validates :prep_time, numericality: { greater_than_or_equal_to: 0 }

  before_save :update_searchable
  after_commit :update_parent_counters, on: [ :create, :update ]
  after_destroy :decrement_parent_counters

  private

  # Update tsvector column for full-text search
  def update_searchable
    searchable_text = [
      title,
      category&.name,
      author&.name,
      ingredients.join(" "),
      cuisine
    ].compact.join(" ")

    # Clean the text to remove problematic characters for tsvector
    # Replace special chars that break tsvector parsing with spaces
    cleaned_text = searchable_text.gsub(/[^\w\s-]/, " ").squeeze(" ").strip

    # Let PostgreSQL automatically convert to tsvector
    self.searchable = cleaned_text
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
