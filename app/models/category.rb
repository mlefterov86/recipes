class Category < ApplicationRecord
  has_many :recipes, dependent: :nullify
  has_many :authors, -> { distinct }, through: :recipes

  validates :name, presence: true, uniqueness: true

  before_validation :normalize_name

  # Refresh the authors_count cache (call after bulk operations)
  def refresh_authors_count!
    update_column(:authors_count, authors.count)
  end

  private

  def normalize_name
    self.name = name.strip.titleize if name.present?
  end
end
