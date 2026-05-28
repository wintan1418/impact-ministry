class CreatePartnerships < ActiveRecord::Migration[8.1]
  def change
    create_table :partnerships do |t|
      t.string :organization_name, null: false
      t.string :contact_name,      null: false
      t.string :contact_email,     null: false
      t.string :contact_phone
      t.string :organization_type, null: false, default: "other"
      t.string :interest_areas,    array: true, default: []
      t.text   :message,           null: false
      t.string :status,            null: false, default: "new"

      t.timestamps
    end

    add_index :partnerships, :status
    add_index :partnerships, :created_at, order: { created_at: :desc }
    add_index :partnerships, :organization_type
  end
end
