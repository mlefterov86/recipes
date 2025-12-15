class CreateRecipes < ActiveRecord::Migration[8.1]
  # Note: disable_ddl_transaction! is NOT needed for creating new tables
  # It's only needed when adding indexes to EXISTING tables with data

  def change
    # Enable UUID extension for PostgreSQL
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :recipes, id: :uuid do |t|
      t.string :title, null: false
      t.integer :cook_time, null: false, default: 0
      t.integer :prep_time, null: false, default: 0
      t.jsonb :ingredients, null: false, default: []
      t.decimal :ratings, precision: 3, scale: 2, null: false, default: 0.00
      t.string :cuisine
      t.references :category, type: :uuid, foreign_key: true
      t.references :author, type: :uuid, foreign_key: true
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
    add_index :recipes, [ :category_id, :ratings ],
              order: { ratings: :desc },
              name: 'index_recipes_on_category_and_ratings'

    # Composite index: Author + Rating
    # For queries like "Chef John's top rated recipes"
    add_index :recipes, [ :author_id, :ratings ],
              order: { ratings: :desc },
              name: 'index_recipes_on_author_and_ratings'

    # Composite index: Category + Author + Rating
    # For queries like "Chef John's top rated Cornbread recipes"
    add_index :recipes, [ :category_id, :author_id, :ratings ],
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
