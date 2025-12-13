class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    # Enable UUID extension for PostgreSQL
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :categories, id: :uuid do |t|
      t.string :name, null: false

      # Counter caches
      t.integer :recipes_count, default: 0, null: false
      t.integer :authors_count, default: 0, null: false

      t.timestamps
    end

    add_index :categories, :name, unique: true
  end
end
