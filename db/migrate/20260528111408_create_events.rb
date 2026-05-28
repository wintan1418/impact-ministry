class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string   :title,            null: false
      t.string   :slug,             null: false
      t.text     :description
      t.datetime :starts_at,        null: false
      t.datetime :ends_at
      t.string   :location
      t.string   :virtual_link
      t.integer  :capacity
      t.boolean  :published,        null: false, default: false
      t.string   :cover_photo_slug

      t.timestamps
    end

    add_index :events, :slug,                       unique: true
    add_index :events, :starts_at
    add_index :events, [ :published, :starts_at ]
  end
end
