class CreateProcessedStripeEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :processed_stripe_events do |t|
      t.string :stripe_event_id, null: false
      t.string :event_type,      null: false
      t.datetime :processed_at,  null: false
      t.timestamps
    end

    add_index :processed_stripe_events, :stripe_event_id, unique: true
    add_index :processed_stripe_events, :event_type
  end
end
