class CreateDevotionalDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :devotional_deliveries do |t|
      t.references :devotional, null: false, foreign_key: true
      t.references :email_subscriber, null: false, foreign_key: true
      t.datetime :sent_at, null: false
      t.datetime :opened_at
      t.datetime :clicked_at
      t.string :postmark_message_id

      t.timestamps
    end

    # One delivery per (devotional, subscriber). Webhook re-runs and job
    # retries both rely on this for idempotency.
    add_index :devotional_deliveries,
              [ :devotional_id, :email_subscriber_id ],
              unique: true,
              name: "index_devotional_deliveries_on_devotional_and_subscriber"

    # postmark_message_id is unique when present (correlates webhook events).
    # Partial index in Postgres so multiple NULLs are allowed.
    add_index :devotional_deliveries,
              :postmark_message_id,
              unique: true,
              where: "postmark_message_id IS NOT NULL",
              name: "index_devotional_deliveries_on_postmark_message_id"

    add_index :devotional_deliveries, :sent_at
    add_index :devotional_deliveries, :opened_at
    add_index :devotional_deliveries, :clicked_at
  end
end
