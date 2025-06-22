class AddClockInToSleepLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :sleep_logs, :clock_in, :datetime, null: false, precision: nil, default: -> { 'CURRENT_TIMESTAMP()' }
  end
end
