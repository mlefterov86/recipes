# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_13_095324) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "authors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "categories_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "recipes_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_authors_on_name", unique: true
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "authors_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "recipes_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "recipes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "author_id"
    t.uuid "category_id"
    t.integer "cook_time", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "cuisine"
    t.string "image_url"
    t.jsonb "ingredients", default: [], null: false
    t.integer "prep_time", default: 0, null: false
    t.decimal "ratings", precision: 3, scale: 2, default: "0.0", null: false
    t.tsvector "searchable"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "ratings"], name: "index_recipes_on_author_and_ratings", order: { ratings: :desc }
    t.index ["author_id"], name: "index_recipes_on_author_id"
    t.index ["category_id", "author_id", "ratings"], name: "index_recipes_on_category_author_ratings", order: { ratings: :desc }
    t.index ["category_id", "ratings"], name: "index_recipes_on_category_and_ratings", order: { ratings: :desc }
    t.index ["category_id"], name: "index_recipes_on_category_id"
    t.index ["ingredients"], name: "index_recipes_on_ingredients_gin", using: :gin
    t.index ["ratings"], name: "index_recipes_on_ratings"
    t.index ["searchable"], name: "index_recipes_on_searchable_gin", using: :gin
  end

  add_foreign_key "recipes", "authors"
  add_foreign_key "recipes", "categories"
end
