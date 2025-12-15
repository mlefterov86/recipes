class CategorySerializer
  def initialize(category)
    @category = category
  end

  def as_json
    {
      id: category.id,
      name: category.name,
      recipes_count: category.recipes_count
    }
  end

  private

  attr_reader :category
end
