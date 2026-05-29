class CreateDonors < ActiveRecord::Migration[8.1]
  def change
    create_table :donors do |t|
      t.references :user, foreign_key: true, null: true, index: true
      t.string  :stripe_customer_id, null: true
      t.string  :name,               null: false, default: ""
      t.string  :email,              null: false
      t.jsonb   :address,            null: false, default: {}
      t.timestamps
    end

    add_index :donors, :stripe_customer_id, unique: true, where: "stripe_customer_id IS NOT NULL"
    add_index :donors, :email
  end
end
