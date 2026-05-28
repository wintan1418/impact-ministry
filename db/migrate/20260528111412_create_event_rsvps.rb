class CreateEventRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :event_rsvps do |t|
      t.references :event,      null: false, foreign_key: true
      t.string  :name,          null: false
      t.string  :email,         null: false
      t.integer :party_size,    null: false, default: 1
      t.text    :notes

      t.timestamps
    end

    add_index :event_rsvps, [ :event_id, :email ], unique: true
  end
end
