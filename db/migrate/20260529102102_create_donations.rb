class CreateDonations < ActiveRecord::Migration[8.1]
  def change
    create_table :donations do |t|
      t.references :donor, foreign_key: true, null: false, index: true
      t.integer :amount_cents, null: false
      t.string  :currency,     null: false, default: "usd"
      t.string  :frequency,    null: false, default: "once"
      t.string  :designation,  null: false, default: "general"
      t.string  :stripe_payment_intent_id, null: true
      t.string  :stripe_subscription_id,   null: true
      t.string  :stripe_checkout_session_id, null: true
      t.string  :status,       null: false, default: "pending"
      t.datetime :donated_at,      null: true
      t.datetime :receipt_sent_at, null: true
      t.timestamps
    end

    add_index :donations, :stripe_payment_intent_id, unique: true, where: "stripe_payment_intent_id IS NOT NULL"
    add_index :donations, :stripe_subscription_id
    add_index :donations, :stripe_checkout_session_id, unique: true, where: "stripe_checkout_session_id IS NOT NULL"
    add_index :donations, :status
    add_index :donations, :designation
    add_index :donations, :donated_at
  end
end
