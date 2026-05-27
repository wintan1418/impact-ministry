class CreateEmailSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :email_subscribers do |t|
      t.string :email, null: false
      t.string :name
      t.string :source, null: false, default: "manual"
      t.jsonb :preferences, null: false, default: {}
      t.string :token, null: false
      t.datetime :subscribed_at
      t.datetime :unsubscribed_at

      t.timestamps
    end

    add_index :email_subscribers, "lower(email)", unique: true, name: "index_email_subscribers_on_lower_email"
    add_index :email_subscribers, :token, unique: true
    add_index :email_subscribers, :unsubscribed_at
  end
end
