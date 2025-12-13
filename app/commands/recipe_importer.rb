class RecipeImporter
  prepend ServiceObject

  RECIPES_URL = "https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz".freeze
  JSON_FILE_PATH = Rails.root.join("db", "recipes-en.json").freeze
  GZ_FILE_PATH = Rails.root.join("db", "recipes-en.json.gz").freeze

  attr_reader :stats

  def initialize
    @stats = { categories: 0, authors: 0, recipes: 0, errors: [] }
  end

  def call
    puts "🌱 Starting recipe import from #{RECIPES_URL}..."

    json_data = download_and_extract_json_data
    return if failure? # Stop if download/extraction failed

    import_recipes(json_data)
    display_results

    stats
  end

  private

  def download_and_extract_json_data
    # Use existing JSON file if available
    if File.exist?(JSON_FILE_PATH)
      puts "📥 Using existing JSON file at #{JSON_FILE_PATH}"
      puts "   (Delete #{JSON_FILE_PATH} to force fresh download)"
      json_content = File.read(JSON_FILE_PATH)
      return JSON.parse(json_content)
    end

    puts "📥 Downloading and extracting recipes..."

    # Download .gz file
    download_gz_file
    puts "   ✓ Saved to #{GZ_FILE_PATH}"

    # Extract and save JSON
    extract_json
    puts "   ✓ Saved to #{JSON_FILE_PATH}"

    JSON.parse(extract_service.result)
  rescue JSON::ParserError => e
    abort(:import, :parse_error, "Failed to parse JSON: #{e.message}")
  end

  def download_gz_file
    puts "   Downloading #{RECIPES_URL}..."

    abort(:import, :download_failed, download_service.errors.message) if download_service.failure?
  end

  def extract_json
    puts "   Extracting gzip file..."

    abort(:import, :extraction_failed, extract_service.errors.message) if extract_service.failure?
  end

  def download_service
    @download_service ||= FileDownloader.call(url: RECIPES_URL, destination: GZ_FILE_PATH)
  end

  def extract_service
    @extract_service ||= GzipExtractor.call(source: GZ_FILE_PATH, destination: JSON_FILE_PATH)
  end

  def import_recipes(json_data)
    puts "📊 Found #{json_data.length} recipes to import"
    puts "📝 Importing recipes..."

    json_data.each_with_index do |recipe_data, index|
      import_single_recipe(recipe_data)
      print_progress(index + 1, json_data.length)
    rescue StandardError => e
      stats[:errors] << { recipe: recipe_data["title"], error: e.message }
    end

    puts "\n"
  end

  def import_single_recipe(recipe_data)
    category = find_or_create_category(recipe_data["category"])
    author = find_or_create_author(recipe_data["author"])

    Recipe.create!(
      title: recipe_data["title"],
      cook_time: parse_time(recipe_data["cook_time"]),
      prep_time: parse_time(recipe_data["prep_time"]),
      ingredients: recipe_data["ingredients"] || [],
      ratings: parse_rating(recipe_data["ratings"]),
      cuisine: recipe_data["cuisine"],
      category: category,
      author: author,
      image_url: extract_actual_image_url(recipe_data["image"])
    )

    stats[:recipes] += 1
  end

  def find_or_create_category(category_name)
    return nil if category_name.blank?

    category = Category.find_or_initialize_by(name: category_name)
    stats[:categories] += 1 if category.new_record?
    category.save! if category.new_record?
    category
  end

  def find_or_create_author(author_name)
    return nil if author_name.blank?

    author = Author.find_or_initialize_by(name: author_name)
    stats[:authors] += 1 if author.new_record?
    author.save! if author.new_record?
    author
  end

  def parse_time(time_value)
    return 0 if time_value.blank?

    time_value.to_i
  end

  def parse_rating(rating_value)
    return nil if rating_value.blank?

    rating = rating_value.to_f
    rating.between?(0, 5) ? rating.round(2) : nil
  end

  def extract_actual_image_url(image_url)
    return nil if image_url.blank?

    # Parse the proxy URL and extract the actual image URL from the 'url' query parameter
    uri = URI.parse(image_url)
    query_params = URI.decode_www_form(uri.query || "").to_h
    query_params["url"] || image_url
  rescue URI::InvalidURIError, StandardError
    # If parsing fails, return the original URL
    image_url
  end

  def print_progress(current, total)
    return unless current % 100 == 0 || current == total

    percentage = (current.to_f / total * 100).round(1)
    print "\r   Imported #{current}/#{total} recipes (#{percentage}%)"
  end

  def display_results
    puts "✅ Import completed successfully!"
    puts "\n📊 Final Statistics:"
    puts "   - Categories created: #{stats[:categories]}"
    puts "   - Authors created: #{stats[:authors]}"
    puts "   - Recipes imported: #{stats[:recipes]}"

    if stats[:errors].any?
      puts "\n⚠️  Errors encountered: #{stats[:errors].count}"
      stats[:errors].first(5).each do |error|
        puts "   - #{error[:recipe]}: #{error[:error]}"
      end
      puts "   (showing first 5 errors)" if stats[:errors].count > 5
    end

    puts "\n📈 Counter Cache Summary:"
    puts "   - Total recipes: #{Recipe.count}"
    puts "   - Total categories: #{Category.count}"
    puts "   - Total authors: #{Author.count}"
    puts "   - Categories with recipes: #{Category.where('recipes_count > 0').count}"
    puts "   - Authors with recipes: #{Author.where('recipes_count > 0').count}"
  end
end
