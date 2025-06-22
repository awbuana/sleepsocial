class CreateSleepLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :sleep_logs do |t|
      t.integer :user_id, null: false
      t.datetime :clock_out

      t.timestamps
    end
  end
end
