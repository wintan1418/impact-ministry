class AddStreakFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :current_streak, :integer, null: false, default: 0
    add_column :users, :longest_streak, :integer, null: false, default: 0
    add_column :users, :last_read_on, :date
    add_index  :users, :current_streak
  end
end
