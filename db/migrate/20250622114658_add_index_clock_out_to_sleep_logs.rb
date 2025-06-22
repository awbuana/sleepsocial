class AddIndexClockOutToSleepLogs < ActiveRecord::Migration[8.0]
  def change
    add_index :sleep_logs, [ :user_id, :clock_out ]
  end
end
