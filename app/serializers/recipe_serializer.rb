class RecipeSerializer
  def initialize(recipe)
    @recipe = recipe
  end

  def as_json
    {
      id: @recipe.id,
      title: @recipe.title,
      image_url: @recipe.image_url,
      ratings: @recipe.ratings&.to_f,
      cook_time: @recipe.cook_time,
      prep_time: @recipe.prep_time,
      cuisine: @recipe.cuisine,
      category: @recipe.category ? CategorySerializer.new(@recipe.category).as_json : nil,
      author: @recipe.author ? AuthorSerializer.new(@recipe.author).as_json : nil,
      ingredients: @recipe.ingredients
    }
  end

  def as_detail_json
    as_json.merge(
      ingredients: @recipe.ingredients,
      created_at: @recipe.created_at
    )
  end
end
