class CreateFeedbackMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :feedback_messages do |t|
      t.string   :name,     null: false
      t.string   :email,    null: false
      t.string   :subject
      t.text     :body,     null: false
      t.string   :kind,     null: false, default: "general"
      t.boolean  :replied,  null: false, default: false
      t.datetime :replied_at

      t.timestamps
    end

    add_index :feedback_messages, :replied
    add_index :feedback_messages, :created_at, order: { created_at: :desc }
    add_index :feedback_messages, :kind
  end
end
