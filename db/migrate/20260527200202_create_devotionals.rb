class CreateDevotionals < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    create_table :devotionals do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :scripture_reference, null: false
      t.text :excerpt
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.date :scheduled_for, null: false
      t.datetime :published_at
      t.string :tags, array: true, default: []

      t.timestamps
    end

    add_index :devotionals, :slug, unique: true
    add_index :devotionals, :scheduled_for, unique: true
    add_index :devotionals, :published_at
    add_index :devotionals, :tags, using: :gin

    execute <<~SQL.squish
      CREATE INDEX IF NOT EXISTS index_devotionals_on_title_trgm
      ON devotionals USING gin (title gin_trgm_ops)
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_devotionals_on_title_trgm"
    drop_table :devotionals
  end
end
