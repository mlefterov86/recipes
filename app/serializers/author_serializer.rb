class AuthorSerializer
  def initialize(author)
    @author = author
  end

  def as_json
    {
      id: @author.id,
      name: @author.name
    }
  end
end
