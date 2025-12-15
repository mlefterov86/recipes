# Testing Guide

## Running Tests

**RSpec is now configured to ALWAYS use the test database**, protecting your development data.

You can run tests in multiple ways:

### Option 1: From Web Container (Simple & Fast)

```bash
# Run all tests
docker exec recipes-web-1 bundle exec rspec

# Run specific test file
docker exec recipes-web-1 bundle exec rspec spec/models/recipe_spec.rb

# Run specific test
docker exec recipes-web-1 bundle exec rspec spec/models/recipe_spec.rb:216

# Run with different format
docker exec recipes-web-1 bundle exec rspec --format documentation
```

### Option 2: Using Docker Compose

```bash
# From the project directory, you can use docker compose exec
cd /path/to/recipes

# Run all tests
docker compose exec web bundle exec rspec

# Run specific test
docker compose exec web bundle exec rspec spec/models/recipe_spec.rb:10

# Note: This requires the web service to be running
```

## How It Works

RSpec is configured in `spec/spec_helper.rb` and `spec/rails_helper.rb` to:
1. **Force `RAILS_ENV=test`** before loading Rails
2. **Abort if development environment is detected**
3. **Automatically use the test database** (`recipes_test`)

This means you can run tests any way you want without worrying about wiping your development database!

## Shell Aliases (Optional)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Quick alias for running tests from web container
alias drspec='docker exec recipes-web-1 bundle exec rspec'

# Or using docker compose (from project directory)
alias dcrspec='docker compose exec web bundle exec rspec'
```

Then run tests like:
```bash
drspec spec/models/recipe_spec.rb:10
# or
dcrspec spec/models/recipe_spec.rb:10
```

## Test Coverage

### Test Suite Breakdown

**Total: 318 tests - ALL PASSING ✅**

- **API Endpoints**: 52 tests
  - Recipes API: 39 tests (CRUD, filtering, sorting, pagination consistency)
  - Categories API: 6 tests (index, contextual filtering)
  - Authors API: 6 tests (index, contextual filtering)
  - Health Check: 1 test

- **Models**: 163 tests (Recipe, Category, Author)
  - Recipe: 117 tests
    - Validations (title, ingredients, ratings, cook_time, prep_time)
    - Associations (category, author)
    - Filtering scopes (by_category_id, by_author_id)
    - Search scopes (search_title, search_ingredient, full_text_search)
    - Sorting scopes (rating, created, title, author, category)
    - Pagination stability (ID tie-breaker consistency)
    - Callbacks (searchable tsvector updates, counter cache updates)
  - Category: 23 tests (validations, associations, scopes)
  - Author: 23 tests (validations, associations, scopes)

- **Serializers**: 18 tests (Recipe, Category, Author)
  - Recipe: 14 tests (as_json, as_detail_json, nested associations)
  - Category: 2 tests (as_json structure)
  - Author: 2 tests (as_json structure)

- **Concerns**: 12 tests (Paginatable)
  - Pagination logic
  - Page calculation
  - Metadata generation (current_page, total_pages, has_next, has_prev)

- **Services**: 71 tests
  - RecipeImporter: 41 tests (JSON parsing, record creation, error handling)
  - FileDownloader: 15 tests (HTTP downloads, retries, errors)
  - GzipExtractor: 15 tests (extraction, validation, cleanup)

### Recent Test Additions

**Pagination Consistency Tests** (Added 2024-12-15)
- Model-level ID tie-breaker consistency test
- 5 API pagination stability and correctness tests:
  - Page 1 stability (multiple requests return same results)
  - Page 2 stability (multiple requests return same results)
  - Page 1 correctness (verifies exact expected IDs)
  - Page 2 correctness (verifies exact expected IDs)
  - Page 3 correctness (verifies exact expected ID)

These tests ensure that pagination remains consistent when recipes have identical ratings and created_at timestamps by using ID as a tie-breaker.

## Current Status

✅ All 318 tests passing
✅ Development DB automatically protected (10,013 recipes safe)
✅ Test DB properly isolated
✅ No need to remember RAILS_ENV - it's automatic!
✅ Pagination stability guaranteed with comprehensive test coverage
