class AddTestimonyFields < ActiveRecord::Migration[8.1]
  def change
    change_table :testimonies do |t|
      t.string   :name
      t.string   :location
      t.text     :body
      t.boolean  :featured,     null: false, default: false
      t.boolean  :approved,     null: false, default: false
      t.datetime :submitted_at
      t.datetime :approved_at
    end

    # Body is non-null in the domain; backfill safety happens implicitly because
    # the table is freshly created in the prior migration with no rows.
    change_column_null :testimonies, :body, false

    # Public wall query: approved (+ featured) ordered by recency.
    add_index :testimonies, [ :approved, :featured, :submitted_at ],
              order: { submitted_at: :desc },
              name: "index_testimonies_on_approved_featured_submitted"
    add_index :testimonies, :submitted_at
    add_index :testimonies, :approved
  end
end
