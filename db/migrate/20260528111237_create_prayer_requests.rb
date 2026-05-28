class CreatePrayerRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :prayer_requests do |t|
      t.string  :name
      t.string  :email
      t.boolean :is_anonymous,  null: false, default: false
      t.text    :body,          null: false
      t.string  :status,        null: false, default: "new"
      t.boolean :is_public,     null: false, default: false
      t.integer :prayed_count,  null: false, default: 0

      t.timestamps
    end

    # Wall query: visible posts sorted by recency.
    add_index :prayer_requests, [ :status, :is_public, :created_at ],
              order: { created_at: :desc },
              name: "index_prayer_requests_on_status_public_created"
    add_index :prayer_requests, :created_at
    add_index :prayer_requests, :status
  end
end
