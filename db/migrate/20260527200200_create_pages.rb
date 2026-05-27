class CreatePages < ActiveRecord::Migration[8.1]
  def change
    create_table :pages do |t|
      t.string  :slug,      null: false
      t.string  :title,     null: false
      t.jsonb   :seo_meta,  null: false, default: {}
      t.boolean :published, null: false, default: true

      t.timestamps
    end

    add_index :pages, :slug, unique: true
  end
end
