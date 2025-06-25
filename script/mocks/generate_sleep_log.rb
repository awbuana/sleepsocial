# This script generates random SleepLog records for existing users.
# It ensures:
#   - clock_in is not older than 4 days ago.
#   - clock_out is always greater than clock_in.
#   - 5 sleep logs are created for each user.
# This version uses bulk insertion, processing sleep logs in batches of 1000 users' worth
# to optimize performance for a large number of users.

puts "Starting sleep log generation..."

# Ensure that the User model exists and has some records.
# If you don't have users, you might want to create some first, e.g.:
# 5.times { User.create!(name: Faker::Name.name) } # Requires faker gem

users = User.all

if users.empty?
  puts "No users found in the database. Please create some users first."
  puts "Example: 5.times { User.create!(name: Faker::Name.name) }"
else
  all_sleep_logs_to_insert = [] # Array to hold ALL sleep log hashes for bulk insertion
  batch_size_users = 1000 # Number of users to process before a bulk insert
  sleep_logs_per_user = 5 # Number of sleep logs generated per user
  batch_size_records = batch_size_users * sleep_logs_per_user # Total records per batch insert

  users.each_with_index do |user, user_index|
    # puts "\nGenerating sleep logs for User ID: #{user.id} (Name: #{user.name || 'N/A'})" # Too verbose for large batches

    sleep_logs_to_add_for_current_user = [] # Temp array for current user's logs

    sleep_logs_per_user.times do |i|
      # Define the range for clock_in: within the last 4 days from now.
      # Time.current is used for consistency with Rails' time handling.
      # Ensure at least an hour buffer for clock_out calculation
      max_clock_in = Time.current
      min_clock_in = Time.current - 4.days

      # Generate a random clock_in within the specified range.
      # We subtract a random number of seconds to ensure clock_in is in the past,
      # and leave enough room for a reasonable sleep duration.
      # Make sure the random duration subtracted is less than 4 days, ensuring clock_in is within the last 4 days.
      random_seconds_ago = rand(0..(4.days.to_i - 1.hour.to_i)) # At least 1 hour buffer for clock_out
      clock_in = Time.current - random_seconds_ago.seconds

      # Ensure clock_in is not older than 4 days (redundant if random_seconds_ago logic is tight, but good safeguard)
      clock_in = [clock_in, min_clock_in].max

      # Generate clock_out, ensuring it's after clock_in.
      # Sleep duration can be between 4 hours and 10 hours.
      sleep_duration_in_hours = rand(4..10)
      # Add some random minutes for more variety
      sleep_duration_in_minutes = sleep_duration_in_hours * 60 + rand(0..59)

      clock_out = clock_in + sleep_duration_in_minutes.minutes

      # If by some rare chance clock_out is still before clock_in (e.g., due to edge cases in random generation),
      # adjust clock_out to be at least 1 minute after clock_in.
      if clock_out < clock_in
        clock_out = clock_in + 1.minute
      end

      # Add the attributes hash to the array for bulk insertion
      sleep_logs_to_add_for_current_user << {
        user_id: user.id,
        clock_in: clock_in,
        clock_out: clock_out,
        created_at: Time.current, # Always set created_at and updated_at for bulk inserts
        updated_at: Time.current
      }
    end # End of sleep_logs_per_user.times loop

    all_sleep_logs_to_insert.concat(sleep_logs_to_add_for_current_user)

    # Perform bulk insertion if we've reached the batch size for records
    if (user_index + 1) % batch_size_users == 0 || (user_index + 1) == users.length
      if all_sleep_logs_to_insert.any?
        begin
          puts "  Attempting to insert #{all_sleep_logs_to_insert.length} sleep logs for batch ending with User ID: #{user.id}..."
          result = SleepLog.insert_all(all_sleep_logs_to_insert)
          if result
            puts "  Successfully created #{result.length} sleep logs."
          else
            puts "  Failed to insert sleep logs. Result was nil."
          end
        rescue => e
          puts "  Error during bulk insertion for batch ending with User ID: #{user.id}: #{e.message}"
        ensure
          all_sleep_logs_to_insert = [] # Clear the array after insertion attempt
        end
      else
        puts "  No sleep logs to insert for batch ending with User ID: #{user.id}."
      end
    end
  end # End of users.each loop

  # This final check is essentially handled by the `|| (user_index + 1) == users.length` condition
  # inside the loop, but as a safeguard, leaving this comment for clarity if the loop logic changes.
  # if all_sleep_logs_to_insert.any?
  #   begin
  #     puts "  Inserting remaining #{all_sleep_logs_to_insert.length} sleep logs..."
  #     result = SleepLog.insert_all(all_sleep_logs_to_insert)
  #     if result
  #       puts "  Successfully created #{result.length} remaining sleep logs."
  #     else
  #       puts "  Failed to insert remaining sleep logs. Result was nil."
  #     end
  #   rescue => e
  #     puts "  Error during final bulk insertion: #{e.message}"
  #   end
  # end

  puts "\nSleep log generation complete."
end
