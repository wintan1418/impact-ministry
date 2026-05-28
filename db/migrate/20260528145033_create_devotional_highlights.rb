class CreateDevotionalHighlights < ActiveRecord::Migration[8.1]
  def change
    create_table :devotional_highlights do |t|
      t.references :user,       null: false, foreign_key: true
      t.references :devotional, null: false, foreign_key: true
      t.text     :text_range,   null: false
      t.text     :note
      t.datetime :saved_at,     null: false

      t.timestamps
    end

    add_index :devotional_highlights, [ :user_id, :saved_at ]
  end
end
