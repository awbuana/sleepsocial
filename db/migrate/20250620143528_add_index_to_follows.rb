class AddIndexToFollows < ActiveRecord::Migration[8.0]
  def change
    add_index :follows, [ :user_id, :target_user_id ], unique: true
    add_index :follows, [ :target_user_id ]
  end
end
