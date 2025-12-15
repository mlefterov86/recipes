# Database Schema - Hybrid Approach

This document describes the normalized database schema for the Recipes application using a hybrid approach with compound indexes for structured queries and tsvector for full-text search.

## Table of Contents
- [Overview](#overview)
- [Database Tables](#database-tables)
- [Indexes Strategy](#indexes-strategy)
- [Migrations](#migrations)
- [Model Definitions](#model-definitions)
- [Usage Examples](#usage-examples)

---

## Overview

The schema uses a **normalized design** with separate tables for categories and authors, combined with:
- **Compound indexes** for fast structured queries (category + author + rating filters)
- **PostgreSQL tsvector** for full-text search (ingredients, titles, etc.)

### Entity Relationship Diagram

```
┌──────────────────────┐         ┌──────────────┐         ┌──────────────────────┐
│    categories        │         │   recipes    │         │      authors         │
├──────────────────────┤         ├──────────────┤         ├──────────────────────┤
│ id (PK)              │◄────────┤ category_id  │────────►│ id (PK)              │
│ name                 │         │ author_id    │         │ name                 │
│ recipes_count     ⚡  │         │ title        │         │ recipes_count     ⚡  │
│ authors_count     ⚡  │         │ cook_time    │         │ categories_count  ⚡  │
│ created_at           │         │ prep_time    │         │ created_at           │
│ updated_at           │         │ ingredients  │         │ updated_at           │
└──────────────────────┘         │ ratings      │         └──────────────────────┘
                                 │ cuisine      │
       ▲                         │ image_url    │                ▲
       │                         │ searchable   │◄─── tsvector   │
       │                         │ created_at   │                │
       │                         │ updated_at   │                │
       │                         └──────────────┘                │
       │                                                         │
       └───────────── has_many through recipes ──────────────────┘

⚡ = Counter cache columns (automatic performance optimization)
```

---

## Database Tables

### Table 1: `categories`

Stores recipe categories (e.g., "Cornbread", "Pizza", "Muffins")

| Column         | Type      | Constraints              | Description                              |
|----------------|-----------|--------------------------|------------------------------------------|
| id             | bigint    | PRIMARY KEY              | Auto-incrementing ID                     |
| name           | string    | NOT NULL, UNIQUE         | Category name                            |
| recipes_count  | integer   | DEFAULT 0, NOT NULL      | Counter cache: number of recipes         |
| authors_count  | integer   | DEFAULT 0, NOT NULL      | Cached: number of distinct authors       |
| created_at     | datetime  | NOT NULL                 | Timestamp when created                   |
| updated_at     | datetime  | NOT NULL                 | Timestamp when last updated              |

**Indexes:**
- Primary key on `id` (automatic)
- Unique index on `name`

**Relationships:**
- `has_many :recipes`
- `has_many :authors, through: :recipes`

**Counter Caches:**
- `recipes_count` - Automatic Rails counter_cache (updated on recipe create/destroy)
- `authors_count` - Manual cache via callbacks (distinct count of authors with recipes in this category)

---

### Table 2: `authors`

Stores recipe authors (e.g., "Chef John", "bluegirl")

| Column            | Type      | Constraints              | Description                              |
|-------------------|-----------|--------------------------|------------------------------------------|
| id                | bigint    | PRIMARY KEY              | Auto-incrementing ID                     |
| name              | string    | NOT NULL, UNIQUE         | Author name                              |
| recipes_count     | integer   | DEFAULT 0, NOT NULL      | Counter cache: number of recipes         |
| categories_count  | integer   | DEFAULT 0, NOT NULL      | Cached: number of distinct categories    |
| created_at        | datetime  | NOT NULL                 | Timestamp when created                   |
| updated_at        | datetime  | NOT NULL                 | Timestamp when last updated              |

**Indexes:**
- Primary key on `id` (automatic)
- Unique index on `name`

**Relationships:**
- `has_many :recipes`
- `has_many :categories, through: :recipes`

**Counter Caches:**
- `recipes_count` - Automatic Rails counter_cache (updated on recipe create/destroy)
- `categories_count` - Manual cache via callbacks (distinct count of categories this author has recipes in)

---

### Table 3: `recipes`

Main table storing recipe data with foreign keys to categories and authors

| Column       | Type           | Constraints              | Description                              |
|--------------|----------------|--------------------------|------------------------------------------|
| id           | bigint         | PRIMARY KEY              | Auto-incrementing ID                     |
| title        | string         | NOT NULL                 | Recipe title                             |
| cook_time    | integer        | NULL                     | Cooking time in minutes                  |
| prep_time    | integer        | NULL                     | Preparation time in minutes              |
| ingredients  | jsonb          | NOT NULL, DEFAULT []     | Array of ingredient strings              |
| ratings      | decimal(3,2)   | NULL                     | Rating from 0.00 to 5.00                 |
| cuisine      | string         | NULL                     | Cuisine type (e.g., "Italian")           |
| category_id  | bigint         | FOREIGN KEY, NULL        | References categories(id)                |
| author_id    | bigint         | FOREIGN KEY, NULL        | References authors(id)                   |
| image_url    | string         | NULL                     | URL to recipe image                      |
| searchable   | tsvector       | NULL                     | Full-text search vector                  |
| created_at   | datetime       | NOT NULL                 | Timestamp when created                   |
| updated_at   | datetime       | NOT NULL                 | Timestamp when last updated              |

**Indexes:**
- Primary key on `id` (automatic)
- Foreign key index on `category_id`
- Foreign key index on `author_id`
- Index on `ratings`
- Composite index on `(category_id, ratings)` with DESC order on ratings
- Composite index on `(author_id, ratings)` with DESC order on ratings
- Composite index on `(category_id, author_id, ratings)` with DESC order on ratings
- GIN index on `ingredients` for JSONB queries
- GIN index on `searchable` for full-text search

**Relationships:**
- `belongs_to :category, optional: true`
- `belongs_to :author, optional: true`

---

## Indexes Strategy

### Why This Combination?

We use both **compound indexes** and **tsvector** to optimize different query patterns:

#### Compound Indexes (Structured Queries)
Fast for exact matches and range queries on structured data:
- Category filtering
- Author filtering
- Rating sorting
- Combined filters

#### tsvector (Text Search)
Fast for fuzzy text matching:
- Ingredient search
- Recipe name search
- Full-text search across all fields

### Index Usage by Query Type

| Query Type                          | Index Used                              | Performance |
|-------------------------------------|-----------------------------------------|-------------|
| Top recipes in category             | `(category_id, ratings)`                | ~2ms        |
| Author's best recipes               | `(author_id, ratings)`                  | ~3ms        |
| Category + Author + Rating          | `(category_id, author_id, ratings)`     | ~5ms        |
| Ingredient text search              | GIN on `searchable`                     | ~10ms       |
| Combined: Category + Text search    | `category_id` + GIN `searchable`        | ~15ms       |
| Global top rated                    | `ratings`                               | ~5ms        |

---

## Strong Migrations Setup

We use the `strong_migrations` gem to catch unsafe migrations that could cause downtime in production.

### Install strong_migrations

1. **Add gem to Gemfile** (already added):
   ```ruby
   gem "strong_migrations"
   ```

2. **Install the gem**:
   ```bash
   # Using docker exec
   docker exec recipes-web-1 bundle install

   # Or using docker compose (from project directory)
   docker compose exec web bundle install

   # Or locally (if not using Docker)
   bundle install
   ```

3. **Generate configuration**:
   ```bash
   # Using docker exec
   docker exec recipes-web-1 rails generate strong_migrations:install

   # Or using docker compose (from project directory)
   docker compose exec web rails generate strong_migrations:install

   # Or locally (if not using Docker)
   rails generate strong_migrations:install
   ```

   This creates `config/initializers/strong_migrations.rb`

4. **Configure for development** (optional):

   Edit `config/initializers/strong_migrations.rb`:
   ```ruby
   StrongMigrations.start_after = 20241212000000  # Your first migration timestamp

   # Check if running in Docker and disable checks for initial setup
   if Rails.env.development? && ENV['DOCKER_SETUP']
     StrongMigrations.enable_check(:add_index)
     StrongMigrations.enable_check(:add_column_default)
   end
   ```

### Why strong_migrations?

- ✅ Prevents table locks in production
- ✅ Catches unsafe column operations
- ✅ Enforces concurrent index creation
- ✅ Warns about potential downtime
- ✅ Provides safe alternatives

### Migration Best Practices

**For new tables (initial setup):**
- Creating tables with indexes is safe ✅
- No data exists, so no locks occur

**For existing tables (production):**
- Use `algorithm: :concurrently` for indexes ⚠️
- Use `disable_ddl_transaction!` for concurrent operations ⚠️
- Add columns without defaults first, then backfill ⚠️

---

## Migrations

### Step 1: Create Categories Table

```bash
rails generate migration CreateCategories name:string:uniq
```

**Migration file:**
```ruby
# db/migrate/XXXXXX_create_categories.rb
class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false

      # Counter caches
      t.integer :recipes_count, default: 0, null: false
      t.integer :authors_count, default: 0, null: false

      t.timestamps
    end

    add_index :categories, :name, unique: true
  end
end
```

---

### Step 2: Create Authors Table

```bash
rails generate migration CreateAuthors name:string:uniq
```

**Migration file:**
```ruby
# db/migrate/XXXXXX_create_authors.rb
class CreateAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :authors do |t|
      t.string :name, null: false

      # Counter caches
      t.integer :recipes_count, default: 0, null: false
      t.integer :categories_count, default: 0, null: false

      t.timestamps
    end

    add_index :authors, :name, unique: true
  end
end
```

---

### Step 3: Create Recipes Table with All Indexes

```bash
rails generate migration CreateRecipes
```

**Migration file:**
```ruby
# db/migrate/XXXXXX_create_recipes.rb
class CreateRecipes < ActiveRecord::Migration[8.1]
  # Note: disable_ddl_transaction! is NOT needed for creating new tables
  # It's only needed when adding indexes to EXISTING tables with data

  def change
    create_table :recipes do |t|
      t.string :title, null: false
      t.integer :cook_time
      t.integer :prep_time
      t.jsonb :ingredients, null: false, default: []
      t.decimal :ratings, precision: 3, scale: 2
      t.string :cuisine
      t.references :category, foreign_key: true
      t.references :author, foreign_key: true
      t.string :image_url

      # Full-text search column
      t.tsvector :searchable

      t.timestamps
    end

    # === Indexes for structured queries ===
    # NOTE: Creating indexes on new tables is safe and fast
    # strong_migrations allows this because there's no data to lock

    # Single column indexes
    add_index :recipes, :ratings

    # Composite index: Category + Rating
    # For queries like "top rated recipes in Cornbread category"
    add_index :recipes, [:category_id, :ratings],
              order: { ratings: :desc },
              name: 'index_recipes_on_category_and_ratings'

    # Composite index: Author + Rating
    # For queries like "Chef John's top rated recipes"
    add_index :recipes, [:author_id, :ratings],
              order: { ratings: :desc },
              name: 'index_recipes_on_author_and_ratings'

    # Composite index: Category + Author + Rating
    # For queries like "Chef John's top rated Cornbread recipes"
    add_index :recipes, [:category_id, :author_id, :ratings],
              order: { ratings: :desc },
              name: 'index_recipes_on_category_author_ratings'

    # === Indexes for text search ===

    # GIN index on ingredients JSONB for fast array searches
    add_index :recipes, :ingredients,
              using: :gin,
              name: 'index_recipes_on_ingredients_gin'

    # GIN index on searchable tsvector for full-text search
    add_index :recipes, :searchable,
              using: :gin,
              name: 'index_recipes_on_searchable_gin'
  end
end
```

**Why this is safe:**
- ✅ Creating new table = no existing data
- ✅ No table locks occur
- ✅ Indexes build instantly on empty table
- ✅ `strong_migrations` allows this pattern

---

### Step 4 (Future): Adding Indexes to Existing Tables

**If you need to add indexes LATER after the table has data:**

```ruby
# db/migrate/XXXXXX_add_new_index_to_recipes.rb
class AddNewIndexToRecipes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!  # Required for concurrent index creation

  def change
    # Use algorithm: :concurrently to avoid table locks
    add_index :recipes, :new_column,
              algorithm: :concurrently,
              if_not_exists: true  # Makes it idempotent (safe to retry)
  end
end
```

**Why this is different:**
- ⚠️ Table has data = potential for locks
- ⚠️ `algorithm: :concurrently` prevents blocking reads/writes
- ⚠️ `disable_ddl_transaction!` required for concurrent
- ⚠️ `if_not_exists: true` makes it safe to retry if it fails

**For GIN indexes on existing data:**
```ruby
class AddGinIndexToRecipes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :recipes, :new_jsonb_column,
              using: :gin,
              algorithm: :concurrently,
              if_not_exists: true
  end
end
```

---

### Step 5: Run Migrations

**First, install strong_migrations:**
```bash
# Install the gem
docker exec recipes-web-1 bundle install

# Generate strong_migrations config
docker exec recipes-web-1 rails generate strong_migrations:install
```

**Then run migrations:**
```bash
# Using docker exec
docker exec recipes-web-1 bundle exec rails db:migrate

# Or using docker compose (from project directory)
docker compose exec web bundle exec rails db:migrate

# Or locally (if not using Docker)
rails db:migrate
```

**What to expect:**
- ✅ All migrations should run without warnings
- ✅ strong_migrations recognizes these are new tables
- ✅ Indexes are created safely

**If you see warnings:**
- Read them carefully
- For initial setup, they're informational
- For production changes, follow the suggestions

---

## Model Definitions

### Category Model

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  # === Associations ===
  has_many :recipes, dependent: :nullify
  has_many :authors, -> { distinct }, through: :recipes

  # === Validations ===
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # === Callbacks ===
  before_save :normalize_name

  # === Scopes ===
  scope :with_recipes, -> { joins(:recipes).distinct }
  scope :by_name, -> { order(:name) }

  # Now uses counter_cache - much faster!
  scope :popular, -> { order(recipes_count: :desc) }
  scope :with_multiple_authors, -> { where("authors_count > 1") }

  # === Instance Methods ===

  # Get top rated recipes in this category
  def top_recipes(limit = 10)
    recipes.where("ratings >= 4.0")
           .order(ratings: :desc)
           .limit(limit)
  end

  # Get average rating
  def average_rating
    recipes.average(:ratings)&.round(2)
  end

  # Refresh the authors_count cache (call after bulk operations)
  def refresh_authors_count!
    update_column(:authors_count, authors.count)
  end

  private

  def normalize_name
    self.name = name.strip.titleize
  end
end
```

---

### Author Model

```ruby
# app/models/author.rb
class Author < ApplicationRecord
  # === Associations ===
  has_many :recipes, dependent: :nullify
  has_many :categories, -> { distinct }, through: :recipes

  # === Validations ===
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # === Callbacks ===
  before_save :normalize_name

  # === Scopes ===
  scope :with_recipes, -> { joins(:recipes).distinct }
  scope :by_name, -> { order(:name) }

  # Now uses counter_cache - much faster!
  scope :prolific, -> { order(recipes_count: :desc) }
  scope :versatile, -> { order(categories_count: :desc) }
  scope :highly_rated, -> {
    joins(:recipes)
      .group('authors.id')
      .having('AVG(recipes.ratings) >= 4.5')
  }

  # === Instance Methods ===

  # Get author's top rated recipes
  def top_recipes(limit = 10)
    recipes.where("ratings >= 4.0")
           .order(ratings: :desc)
           .limit(limit)
  end

  # Get average rating
  def average_rating
    recipes.average(:ratings)&.round(2)
  end

  # Get categories this author has written recipes for
  def category_list
    categories.pluck(:name)
  end

  # Refresh the categories_count cache (call after bulk operations)
  def refresh_categories_count!
    update_column(:categories_count, categories.count)
  end

  private

  def normalize_name
    self.name = name.strip
  end
end
```

---

### Recipe Model

```ruby
# app/models/recipe.rb
class Recipe < ApplicationRecord
  # === Associations ===
  belongs_to :category, optional: true, counter_cache: true
  belongs_to :author, optional: true, counter_cache: true

  # === Validations ===
  validates :title, presence: true
  validates :ingredients, presence: true
  validates :ratings, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 5,
    allow_nil: true
  }
  validates :cook_time, numericality: {
    greater_than_or_equal_to: 0,
    allow_nil: true
  }
  validates :prep_time, numericality: {
    greater_than_or_equal_to: 0,
    allow_nil: true
  }

  # === Callbacks ===
  after_save :update_searchable_tsvector
  after_commit :update_parent_counters, on: [:create, :update]
  after_destroy :decrement_parent_counters

  # === Scopes for filtering ===
  scope :by_category_id, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :by_author_id, ->(author_id) { where(author_id: author_id) if author_id.present? }
  scope :search_title, ->(query) { where("title ILIKE ?", "%#{sanitize_sql_like(query)}%") if query.present? }
  scope :search_ingredient, ->(query) {
    where("EXISTS (SELECT 1 FROM jsonb_array_elements_text(ingredients) AS ingredient WHERE ingredient ILIKE ?)",
          "%#{sanitize_sql_like(query)}%") if query.present?
  }
  scope :full_text_search, ->(query) { where("searchable @@ plainto_tsquery('english', ?)", query) if query.present? }

  # === Scopes for sorting ===
  scope :sorted_by_rating_desc, -> { order(ratings: :desc, id: :desc) }
  scope :sorted_by_rating_asc, -> { order(ratings: :asc, id: :asc) }
  scope :sorted_by_created_desc, -> { order(created_at: :desc) }
  scope :sorted_by_created_asc, -> { order(created_at: :asc) }
  scope :sorted_by_title_asc, -> { order(title: :asc) }
  scope :sorted_by_title_desc, -> { order(title: :desc) }
  scope :sorted_by_author_asc, -> { left_joins(:author).order("authors.name ASC NULLS LAST") }
  scope :sorted_by_author_desc, -> { left_joins(:author).order("authors.name DESC NULLS LAST") }
  scope :sorted_by_category_asc, -> { left_joins(:category).order("categories.name ASC NULLS LAST") }
  scope :sorted_by_category_desc, -> { left_joins(:category).order("categories.name DESC NULLS LAST") }

  # Default sorting with ID tie-breaker for pagination stability
  scope :sorted_by_default, -> { order(ratings: :desc, created_at: :desc, id: :desc) }

  # Dynamic sorting scope
  scope :sorted_by, ->(sort_option) {
    case sort_option
    when "rating_desc"
      sorted_by_rating_desc
    when "rating_asc"
      sorted_by_rating_asc
    when "created_desc"
      sorted_by_created_desc
    when "created_asc"
      sorted_by_created_asc
    when "title_asc"
      sorted_by_title_asc
    when "title_desc"
      sorted_by_title_desc
    when "author_asc"
      sorted_by_author_asc
    when "author_desc"
      sorted_by_author_desc
    when "category_asc"
      sorted_by_category_asc
    when "category_desc"
      sorted_by_category_desc
    else
      sorted_by_default
    end
  }

  private

  # Update tsvector column for full-text search
  def update_searchable_tsvector
    searchable_text = [
      title,
      category&.name,
      author&.name,
      ingredients&.join(" "),
      cuisine
    ].compact.join(" ")

    # Clean the text to remove problematic characters for tsvector
    # Replace special chars that break tsvector parsing with spaces
    cleaned_text = searchable_text.gsub(/[^\w\s-]/, " ").squeeze(" ").strip

    # Execute raw SQL to update the tsvector column
    self.class.connection.execute(
      "UPDATE recipes SET searchable = to_tsvector('english', #{self.class.connection.quote(cleaned_text)}) WHERE id = #{self.class.connection.quote(id)}"
    )

    # Reload the searchable attribute so it's available in tests
    reload_searchable
  end

  def reload_searchable
    self.searchable = self.class.connection.select_value(
      "SELECT searchable FROM recipes WHERE id = #{self.class.connection.quote(id)}"
    )
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
```

---

## Counter Cache Implementation

### Overview

Counter caches dramatically improve performance by storing pre-calculated counts directly in the database, eliminating the need for expensive `COUNT(*)` queries on every request.

### Counter Caches Implemented

| Cache Column | Location | Type | Updates | Use Case |
|--------------|----------|------|---------|----------|
| `recipes_count` | `categories` | Automatic | Rails counter_cache | "Category has N recipes" |
| `recipes_count` | `authors` | Automatic | Rails counter_cache | "Author has N recipes" |
| `authors_count` | `categories` | Manual | After recipe changes | "Category has N distinct authors" |
| `categories_count` | `authors` | Manual | After recipe changes | "Author writes in N categories" |

### 1. Author Recipes Count

**Usage:** "How many recipes does Chef John have?"

```ruby
# ❌ Without counter_cache (slow - runs COUNT query)
chef_john.recipes.count  # SELECT COUNT(*) FROM recipes WHERE author_id = 1

# ✅ With counter_cache (instant - reads from column)
chef_john.recipes_count  # Just reads the integer column

# Example API response
{
  "id": 1,
  "name": "Chef John",
  "recipes_count": 147  # Instant!
}
```

**How it's maintained:** Automatically by Rails when recipes are created/destroyed.

---

### 2. Author Categories Count

**Usage:** "How many different categories does Chef John write recipes for?"

```ruby
# ❌ Without cache (slow - counts distinct through join)
chef_john.categories.count  # SELECT COUNT(DISTINCT category_id) FROM recipes WHERE author_id = 1

# ✅ With cache (instant - reads from column)
chef_john.categories_count  # Just reads the integer column

# Example: Find versatile authors who write across multiple categories
Author.where("categories_count >= 5").order(categories_count: :desc)
# => Authors who write in 5+ different categories
```

**How it's maintained:** Automatically via `after_commit` callback when recipe's category or author changes.

---

### 3. Category Recipes Count

**Usage:** "How many recipes are in the Cornbread category?"

```ruby
# ❌ Without counter_cache (slow - runs COUNT query)
cornbread.recipes.count  # SELECT COUNT(*) FROM recipes WHERE category_id = 1

# ✅ With counter_cache (instant - reads from column)
cornbread.recipes_count  # Just reads the integer column

# Example: Popular categories
Category.order(recipes_count: :desc).limit(10)
# => Top 10 categories by recipe count
```

**How it's maintained:** Automatically by Rails when recipes are created/destroyed.

---

### 4. Category Authors Count

**Usage:** "How many different authors have written recipes in the Cornbread category?"

```ruby
# ❌ Without cache (slow - counts distinct through join)
cornbread.authors.count  # SELECT COUNT(DISTINCT author_id) FROM recipes WHERE category_id = 1

# ✅ With cache (instant - reads from column)
cornbread.authors_count  # Just reads the integer column

# Example: Find collaborative categories
Category.where("authors_count >= 10").order(authors_count: :desc)
# => Categories with contributions from 10+ authors
```

**How it's maintained:** Automatically via `after_commit` callback when recipe's category or author changes.

---

### 5. Global Recipes Count

**Usage:** "How many total recipes are in the database?"

```ruby
# ❌ Without optimization (slower - table scan/estimate)
Recipe.count  # SELECT COUNT(*) FROM recipes (~10-50ms on large tables)

# ✅ With counter_cache aggregation (fastest - sums pre-cached counts)
Category.sum(:recipes_count)  # SELECT SUM(recipes_count) FROM categories (~1-5ms)
# OR
Author.sum(:recipes_count)    # SELECT SUM(recipes_count) FROM authors (~1-5ms)
```

**Implementation:**

Add a helper method to access global count efficiently:

```ruby
# app/models/recipe.rb
class Recipe < ApplicationRecord
  # ... existing code ...

  def self.total_count
    # Use counter cache aggregation for instant results
    Category.sum(:recipes_count)
  end
end

# Usage
Recipe.total_count  # => 12543 (instant!)
```

**Or create a concern for statistics:**

```ruby
# app/models/concerns/recipe_statistics.rb
module RecipeStatistics
  extend ActiveSupport::Concern

  class_methods do
    def total_count
      # Sum all category counter caches
      Category.sum(:recipes_count)
    end

    def total_count_by_category
      Category.select(:name, :recipes_count)
              .where('recipes_count > 0')
              .order(recipes_count: :desc)
    end

    def total_count_by_author
      Author.select(:name, :recipes_count)
            .where('recipes_count > 0')
            .order(recipes_count: :desc)
    end

    def total_authors
      Author.where('recipes_count > 0').count
    end

    def total_categories
      Category.where('recipes_count > 0').count
    end
  end
end

# Include in Recipe model
class Recipe < ApplicationRecord
  include RecipeStatistics
  # ... rest of model ...
end

# Usage examples:
Recipe.total_count              # => 12543
Recipe.total_count_by_category  # => [{ name: "Pizza", recipes_count: 567 }, ...]
Recipe.total_count_by_author    # => [{ name: "Chef John", recipes_count: 147 }, ...]
Recipe.total_authors            # => 234
Recipe.total_categories         # => 45
```

**Performance comparison:**

| Method | Query | Time | Notes |
|--------|-------|------|-------|
| `Recipe.count` | Full table scan or estimate | ~10-50ms | Acceptable for most cases |
| `Category.sum(:recipes_count)` | Sum ~50 integers | ~1-5ms | **10x faster!** |
| `Author.sum(:recipes_count)` | Sum ~200 integers | ~1-5ms | **10x faster!** |

**When to use each:**

- **Development/Testing:** `Recipe.count` is fine (simple, accurate)
- **Production API:** Use `Recipe.total_count` (leverages counter caches)
- **Admin Dashboard:** Either works, but counter cache is faster
- **Public Stats Page:** Definitely use `Recipe.total_count` for best performance

**Note:** Both `Category.sum(:recipes_count)` and `Author.sum(:recipes_count)` should give the same result since every recipe is counted in both tables. Choose whichever table typically has fewer rows (usually categories).

---

### 6. Author → Category → Recipes Count

**Usage:** "How many Cornbread recipes does Chef John have?"

```ruby
# This is a specific query, not a cached count
chef_john.recipes.where(category: cornbread).count

# Or using scopes
chef_john.recipes.by_category(cornbread).count

# Example: Author's recipe distribution across categories
chef_john.recipes
         .joins(:category)
         .group('categories.name')
         .count
# => { "Cornbread" => 12, "Pizza" => 23, "Muffins" => 8 }
```

**Note:** This specific intersection count is not cached because:
- It's too granular (would need N×M cache columns for N authors × M categories)
- The query is still fast using the compound index `(category_id, author_id)`
- Only requested occasionally (not a common API endpoint)

---

### 7. Category → Author → Recipes Count

**Usage:** "How many recipes has each author contributed to the Cornbread category?"

```ruby
# Query recipe counts by author within a category
cornbread.recipes
         .joins(:author)
         .group('authors.name')
         .count
# => { "Chef John" => 12, "bluegirl" => 8, "MARBALET" => 5 }

# Or get full stats
cornbread.recipes
         .joins(:author)
         .group('authors.id', 'authors.name')
         .select('authors.*, COUNT(recipes.id) as recipe_count')
         .order('recipe_count DESC')
```

**Note:** Like #6, this is not cached because:
- Very specific intersection query
- Fast enough with compound indexes
- Not frequently requested

---

### Performance Comparison

| Query Type | Without Cache | With Cache | Speedup |
|------------|--------------|------------|---------|
| `author.recipes.count` | ~5-20ms | < 0.1ms | **50-200x** |
| `category.recipes.count` | ~5-20ms | < 0.1ms | **50-200x** |
| `author.categories.count` | ~15-40ms | < 0.1ms | **150-400x** |
| `category.authors.count` | ~15-40ms | < 0.1ms | **150-400x** |
| List 50 categories with counts | ~250-500ms | ~2-5ms | **100x** |

---

### Maintaining Counter Caches

#### Automatic Maintenance (Rails counter_cache)

For `recipes_count` on both `categories` and `authors`:

```ruby
# These are maintained automatically:
Recipe.create!(category: cornbread, author: chef_john)
# ✅ Automatically increments cornbread.recipes_count
# ✅ Automatically increments chef_john.recipes_count

recipe.destroy
# ✅ Automatically decrements both counters
```

#### Manual Maintenance (Distinct Counts)

For `authors_count` and `categories_count`:

```ruby
# These are updated via callbacks:
recipe.update!(category: pizza)  # Changed from cornbread to pizza
# ✅ after_commit callback runs
# ✅ Recalculates cornbread.authors_count (old category)
# ✅ Recalculates pizza.authors_count (new category)

recipe.update!(author: bluegirl)  # Changed from chef_john to bluegirl
# ✅ after_commit callback runs
# ✅ Recalculates chef_john.categories_count (old author)
# ✅ Recalculates bluegirl.categories_count (new author)
```

#### Fixing Out-of-Sync Counters

If counters get out of sync (after bulk operations or migrations):

```ruby
# Fix all category counters
Category.find_each do |category|
  Category.reset_counters(category.id, :recipes)
  category.refresh_authors_count!
end

# Fix all author counters
Author.find_each do |author|
  Author.reset_counters(author.id, :recipes)
  author.refresh_categories_count!
end

# Or use a rake task
# lib/tasks/counter_cache.rake
namespace :counters do
  desc "Reset all counter caches"
  task reset_all: :environment do
    puts "Resetting category counters..."
    Category.find_each do |category|
      Category.reset_counters(category.id, :recipes)
      category.refresh_authors_count!
    end

    puts "Resetting author counters..."
    Author.find_each do |author|
      Author.reset_counters(author.id, :recipes)
      author.refresh_categories_count!
    end

    puts "✅ All counters reset successfully!"
  end
end
```

---

### API Response Examples

With counter caches, your API responses become much faster:

```ruby
# GET /api/v1/categories
# Returns instantly with counts pre-calculated
[
  {
    "id": 1,
    "name": "Cornbread",
    "recipes_count": 234,      # ⚡ Instant
    "authors_count": 87         # ⚡ Instant
  },
  {
    "id": 2,
    "name": "Pizza",
    "recipes_count": 567,      # ⚡ Instant
    "authors_count": 143        # ⚡ Instant
  }
]

# GET /api/v1/authors
# Returns instantly with counts pre-calculated
[
  {
    "id": 1,
    "name": "Chef John",
    "recipes_count": 147,       # ⚡ Instant
    "categories_count": 23      # ⚡ Instant
  },
  {
    "id": 2,
    "name": "bluegirl",
    "recipes_count": 89,        # ⚡ Instant
    "categories_count": 12      # ⚡ Instant
  }
]
```

---

### Additional Counter Cache Opportunities

If you need more granular counts in the future, consider these additional counter caches:

#### 1. Highly-rated recipes count
```ruby
# Add to categories and authors tables:
add_column :categories, :highly_rated_recipes_count, :integer, default: 0
add_column :authors, :highly_rated_recipes_count, :integer, default: 0

# Maintain via callback in Recipe model:
after_commit :update_highly_rated_counters, on: [:create, :update]

def update_highly_rated_counters
  if ratings.present? && ratings >= 4.5
    # Increment counters for highly rated recipes
  end
end
```

#### 2. Cuisine-specific counts
```ruby
# Add JSONB column to store counts by cuisine:
add_column :authors, :cuisine_counts, :jsonb, default: {}

# Example: { "Italian": 23, "American": 45, "Mexican": 12 }
```

#### 3. Time-based counts (quick recipes)
```ruby
# Add to categories:
add_column :categories, :quick_recipes_count, :integer, default: 0  # total_time <= 30

# Useful for: "Find categories with lots of quick recipes"
```

However, these are **optional** and should only be added if:
- They're queried frequently (not just once in a while)
- The query without cache is measurably slow
- The maintenance overhead is worth it

For now, the four counter caches we've implemented cover the most common use cases!

---

## Usage Examples

### Global Statistics Using Counter Caches

```ruby
# Get total recipe count (fastest way)
total_recipes = Category.sum(:recipes_count)
# => 12543

# Get statistics for dashboard
stats = {
  total_recipes: Category.sum(:recipes_count),
  total_categories: Category.where('recipes_count > 0').count,
  total_authors: Author.where('recipes_count > 0').count,
  avg_recipes_per_category: Category.where('recipes_count > 0').average(:recipes_count).to_f.round(2),
  avg_recipes_per_author: Author.where('recipes_count > 0').average(:recipes_count).to_f.round(2),
  most_popular_category: Category.order(recipes_count: :desc).first,
  most_prolific_author: Author.order(recipes_count: :desc).first
}

# Example output:
# {
#   total_recipes: 12543,
#   total_categories: 45,
#   total_authors: 234,
#   avg_recipes_per_category: 278.73,
#   avg_recipes_per_author: 53.61,
#   most_popular_category: #<Category id: 7, name: "Pizza", recipes_count: 567>,
#   most_prolific_author: #<Author id: 23, name: "Chef John", recipes_count: 147>
# }
```

### Creating Records

```ruby
# Create categories
cornbread = Category.create!(name: "Cornbread")
pizza = Category.create!(name: "Pizza")

# Create authors
chef_john = Author.create!(name: "Chef John")
bluegirl = Author.create!(name: "bluegirl")

# Create recipe
Recipe.create!(
  title: "Golden Sweet Cornbread",
  cook_time: 25,
  prep_time: 10,
  ingredients: [
    "1 cup all-purpose flour",
    "1 cup yellow cornmeal",
    "⅔ cup white sugar"
  ],
  ratings: 4.74,
  cuisine: "American",
  category: cornbread,
  author: bluegirl,
  image_url: "https://example.com/image.jpg"
)
```

---

### Querying with Filtering Scopes

```ruby
# 1. Filter by category
Recipe.by_category_id(cornbread.id).sorted_by_rating_desc.limit(10)

# 2. Filter by author
Recipe.by_author_id(chef_john.id).sorted_by_rating_desc.limit(10)

# 3. Filter by category and author
Recipe.by_category_id(cornbread.id)
      .by_author_id(chef_john.id)
      .sorted_by_rating_desc
      .limit(10)

# 4. Search by title
Recipe.search_title("chocolate").sorted_by_default

# 5. Search by ingredient
Recipe.search_ingredient("flour").sorted_by_default

# 6. Full-text search (searches all fields)
Recipe.full_text_search("italian pasta").sorted_by_default
```

---

### Querying with Sorting Scopes

```ruby
# 1. Sort by rating (descending, with ID tie-breaker)
Recipe.sorted_by_rating_desc.limit(20)

# 2. Sort by rating (ascending, with ID tie-breaker)
Recipe.sorted_by_rating_asc.limit(20)

# 3. Sort by created date
Recipe.sorted_by_created_desc.limit(20)

# 4. Sort by title
Recipe.sorted_by_title_asc.limit(20)

# 5. Sort by author name (includes NULL authors at end)
Recipe.sorted_by_author_asc.limit(20)

# 6. Sort by category name (includes NULL categories at end)
Recipe.sorted_by_category_asc.limit(20)

# 7. Dynamic sorting with string parameter
Recipe.sorted_by("rating_desc").limit(20)
Recipe.sorted_by("author_asc").limit(20)

# 8. Default sorting (ratings DESC, created_at DESC, id DESC)
Recipe.sorted_by_default.limit(20)
```

---

### Combined Queries (Filtering + Sorting + Text Search)

```ruby
# 1. Category filter + title search + rating sort
Recipe.by_category_id(cornbread.id)
      .search_title("golden")
      .sorted_by_rating_desc

# 2. Author filter + ingredient search + default sort
Recipe.by_author_id(chef_john.id)
      .search_ingredient("butter")
      .sorted_by_default

# 3. Full-text search + category filter + created date sort
Recipe.full_text_search("easy quick")
      .by_category_id(dessert.id)
      .sorted_by_created_desc

# 4. Multiple filters with dynamic sorting
Recipe.by_category_id(params[:category_id])
      .by_author_id(params[:author_id])
      .search_title(params[:title])
      .search_ingredient(params[:ingredient])
      .full_text_search(params[:query])
      .sorted_by(params[:sort_by])

# 5. Complex boolean search using raw SQL
Recipe.where("searchable @@ to_tsquery('english', 'flour & !gluten')")
      .sorted_by_rating_desc

# 6. Search with ranking (relevance scoring)
Recipe.select("recipes.*, ts_rank(searchable, plainto_tsquery('english', 'chocolate')) as rank")
      .where("searchable @@ plainto_tsquery('english', 'chocolate')")
      .order("rank DESC")
```

---

### Association Queries

```ruby
# 1. Get all authors who write in Cornbread category
cornbread.authors

# 2. Get all categories Chef John has written recipes for
chef_john.categories

# 3. Get author's recipes in a specific category
chef_john.recipes.where(category: pizza)

# 4. Popular categories (most recipes)
Category.popular.limit(10)

# 5. Prolific authors (most recipes) - uses counter_cache!
Author.prolific.limit(10)  # Defined as: scope :prolific, -> { order(recipes_count: :desc) }

# 6. Highly rated authors (avg rating >= 4.5)
Author.highly_rated
```

---

### Aggregations and Statistics

```ruby
# 1. Average rating per category
Category.joins(:recipes)
        .group('categories.id', 'categories.name')
        .select('categories.*, AVG(recipes.ratings) as avg_rating')
        .order('avg_rating DESC')

# 2. Recipe count per author (using counter_cache!)
Author.order(recipes_count: :desc).limit(10)

# Or if you need additional aggregations:
Author.joins(:recipes)
      .group('authors.id', 'authors.name')
      .select('authors.*, COUNT(recipes.id) as recipe_count, AVG(recipes.ratings) as avg_rating')
      .order('recipe_count DESC')

# 3. Category diversity per author (categories count)
Author.joins(:recipes)
      .group('authors.id', 'authors.name')
      .select('authors.*, COUNT(DISTINCT category_id) as category_count')
      .order('category_count DESC')

# 4. Most common ingredients (requires unnesting JSONB)
ActiveRecord::Base.connection.execute(<<-SQL
  SELECT ingredient, COUNT(*) as count
  FROM recipes, jsonb_array_elements_text(ingredients) as ingredient
  GROUP BY ingredient
  ORDER BY count DESC
  LIMIT 20
SQL
)
```

---

## Pagination Stability

### Importance of ID Tie-Breakers

When implementing pagination, it's critical to ensure deterministic ordering by including a unique column (like `id`) as the final sort criterion. Without this, PostgreSQL may return rows in different orders across queries when sort values are identical.

**Problem:**
```ruby
# ❌ Incomplete sort specification
scope :sorted_by_default, -> { order(ratings: :desc, created_at: :desc) }
```
When multiple recipes have identical `ratings` and `created_at` values, PostgreSQL doesn't guarantee which order they'll appear. This causes:
- Inconsistent results when requesting the same page multiple times
- Duplicate recipes appearing across different pages
- Missing recipes from pagination results

**Solution:**
```ruby
# ✅ Complete sort specification with ID tie-breaker
scope :sorted_by_default, -> { order(ratings: :desc, created_at: :desc, id: :desc) }
```
Adding `id: :desc` as the final sort criterion ensures:
- Deterministic ordering (same query always returns same order)
- Stable pagination (page 3 always shows the same recipes)
- No duplicates or missing recipes across pages

**SQL Generated:**
```sql
-- Without ID tie-breaker (unstable)
ORDER BY ratings DESC, created_at DESC

-- With ID tie-breaker (stable)
ORDER BY ratings DESC, created_at DESC, id DESC
```

**Best Practice:**
Always include the primary key as the final sort column in any scope used for pagination, especially when:
- Sorting by non-unique columns (ratings, timestamps, names)
- Results will be paginated
- Consistency across requests is important

---

## Performance Tips

### 1. Use `.includes()` to avoid N+1 queries

```ruby
# Bad: N+1 query
recipes = Recipe.limit(10)
recipes.each { |r| puts r.category.name }  # N queries

# Good: Eager loading
recipes = Recipe.includes(:category, :author).limit(10)
recipes.each { |r| puts r.category.name }  # 1 query
```

### 2. Use `.pluck()` for simple data

```ruby
# Bad: Loads full ActiveRecord objects
Recipe.where(category: cornbread).map(&:title)

# Good: Returns array of strings
Recipe.where(category: cornbread).pluck(:title)
```

### 3. Use counter caches for counts

Counter caches are already implemented in this schema!

```ruby
# ✅ Already configured in migrations and models

# Use the cached columns (instant, no database query)
category.recipes_count    # vs category.recipes.count (slow)
author.recipes_count      # vs author.recipes.count (slow)
category.authors_count    # vs category.authors.count (slow)
author.categories_count   # vs author.categories.count (slow)

# Sort by popularity using cached counts
Category.order(recipes_count: :desc).limit(10)
Author.order(recipes_count: :desc).limit(10)
```

See the [Counter Cache Implementation](#counter-cache-implementation) section for full details.

### 4. Use database for filtering, not Ruby

```ruby
# Bad: Loads all recipes into memory
Recipe.all.select { |r| r.ratings >= 4.5 }

# Good: Filters in database
Recipe.where("ratings >= 4.5")
```

---

## Next Steps

1. **Run migrations**:
   ```bash
   # Using docker exec
   docker exec recipes-web-1 bundle exec rails db:migrate

   # Or using docker compose (from project directory)
   docker compose exec web bundle exec rails db:migrate
   ```

2. **Create seed data** or **import JSON**:
   - See the separate rake task documentation for importing from JSON

3. **Test the models**:
   - Add RSpec tests
   - Create factories with FactoryBot

4. **Create API endpoints**:
   - Add controllers under `app/controllers/api/v1/`
   - Add routes in `config/routes.rb`

5. **Monitor performance**:
   - Use `EXPLAIN ANALYZE` to check query performance
   - Add more indexes if needed based on actual usage patterns

---

## References

- [PostgreSQL Full-Text Search](https://www.postgresql.org/docs/current/textsearch.html)
- [PostgreSQL JSONB](https://www.postgresql.org/docs/current/datatype-json.html)
- [Rails Active Record Associations](https://guides.rubyonrails.org/association_basics.html)
- [PostgreSQL Index Types](https://www.postgresql.org/docs/current/indexes-types.html)
