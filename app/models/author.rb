class Author < ApplicationRecord
  has_many :recipes, dependent: :nullify
  has_many :categories, -> { distinct }, through: :recipes

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_save :normalize_name

  # Refresh the categories_count cache (call after bulk operations)
  def refresh_categories_count!
    update_column(:categories_count, categories.count)
  end

  private

  def normalize_name
    self.name = name.strip
  end
end
