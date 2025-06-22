class AddNumFollowingFollowersToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :num_following, :integer, null: false, default: 0
    add_column :users, :num_followers, :integer, null: false, default: 0
  end
end
