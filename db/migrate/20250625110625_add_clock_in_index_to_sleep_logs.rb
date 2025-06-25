class AddClockInIndexToSleepLogs < ActiveRecord::Migration[8.0]
  def change
    add_index :sleep_logs, [ :user_id, :clock_in ], order: { user_id: :asc, clock_in: :desc}
  end
end
