class AddUserIdIndexToUsers < ActiveRecord::Migration[8.0]
  def change
    add_index :follows, [ :user_id ]
  end
end
