class CreateVolunteers < ActiveRecord::Migration[8.1]
  def change
    create_table :volunteers do |t|
      t.string  :name,          null: false
      t.string  :email,         null: false
      t.string  :phone,         null: true
      t.string  :availability,  null: false, default: "flexible"
      t.string  :status,        null: false, default: "new"
      t.string  :interest_areas, array: true, null: false, default: []
      t.text    :gifts,         null: true
      t.text    :message,       null: false
      t.timestamps
    end

    add_index :volunteers, :email
    add_index :volunteers, :status
    add_index :volunteers, :created_at
  end
end
