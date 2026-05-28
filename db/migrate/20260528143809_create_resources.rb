class CreateResources < ActiveRecord::Migration[8.1]
  def change
    create_table :resources do |t|
      t.string   :title,             null: false
      t.string   :slug,              null: false
      t.text     :description
      t.string   :category,          null: false, default: "guide"
      t.integer  :downloads_count,   null: false, default: 0
      t.boolean  :requires_email,    null: false, default: true
      t.boolean  :featured,          null: false, default: false
      t.datetime :published_at
      t.string   :cover_photo_slug

      t.timestamps
    end

    add_index :resources, :slug, unique: true
    add_index :resources, [ :category, :published_at ], order: { published_at: :desc }
    add_index :resources, :published_at
    add_index :resources, :featured
  end
end
