class CreateAuthors < ActiveRecord::Migration[8.1]
  def change
    # Enable UUID extension for PostgreSQL
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :authors, id: :uuid do |t|
      t.string :name, null: false

      # Counter caches
      t.integer :recipes_count, default: 0, null: false
      t.integer :categories_count, default: 0, null: false

      t.timestamps
    end

    add_index :authors, :name, unique: true
  end
end
