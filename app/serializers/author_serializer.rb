class AuthorSerializer
  def initialize(author)
    @author = author
  end

  def as_json
    {
      id: author.id,
      name: author.name,
      recipes_count: author.recipes_count
    }
  end

  private

  attr_reader :author
end
