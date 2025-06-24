class AddLastBackfillAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_backfill_at, :datetime
  end
end
