puts "Starting user generation..."

# Define the total number of users to generate
total_users = 1_000_000
# Define the batch size for insertions to manage memory
batch_size = 5_000

# Get the current time for timestamps
current_time = Time.current

# Initialize a counter for tracking progress
generated_count = 0

# Loop to generate users in batches
(total_users / batch_size).times do |i|
  users_data = []
  batch_start_index = i * batch_size

  batch_size.times do |j|
    user_index = batch_start_index + j + 1
    users_data << {
      name: "User_#{user_index}_#{SecureRandom.hex(4)}", # Generate unique names
      num_following: 0,
      num_followers: 0,
      created_at: current_time,
      updated_at: current_time
      # last_backfill_at can be nil, or set to current_time if desired
    }
  end

  # Perform the bulk insert
  # `insert_all` does not trigger ActiveRecord callbacks or validations,
  # which is why we manually set `created_at` and `updated_at`.
  User.insert_all(users_data)

  generated_count += batch_size
  puts "Generated #{generated_count} users..."
end

  # Handle any remaining users if total_users is not perfectly divisible by batch_size
  remaining_users = total_users % batch_size
begin
  if remaining_users > 0
    users_data = []
    batch_start_index = total_users - remaining_users
    remaining_users.times do |j|
      user_index = batch_start_index + j + 1
      users_data << {
        name: "User_#{user_index}_#{SecureRandom.hex(4)}",
        num_following: 0,
        num_followers: 0,
        created_at: current_time,
        updated_at: current_time
      }
    end
    User.insert_all(users_data)
    generated_count += remaining_users
    puts "Generated #{generated_count} users (final batch)..."
  end

  puts "User generation complete. #{total_users} users created!"
rescue StandardError => e
  puts "An error occurred during user generation: #{e.message}"
  puts e.backtrace.join("\n")
end
