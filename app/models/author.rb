class Author < ApplicationRecord
  has_many :recipes, dependent: :nullify
  has_many :categories, -> { distinct }, through: :recipes

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_name

  # Scope to filter authors that have recipes in a specific category
  scope :by_category, ->(category_id = nil) {
    if category_id.present?
      joins(:recipes).where(recipes: { category_id: category_id }).distinct
    else
      all
    end
  }

  # Refresh the categories_count cache (call after bulk operations)
  def refresh_categories_count!
    update_column(:categories_count, categories.count)
  end

  private

  def normalize_name
    self.name = name.strip if name.present?
  end
end
