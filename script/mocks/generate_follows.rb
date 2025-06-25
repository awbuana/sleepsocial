# Define the batch size for insertions to manage memory
batch_size = 5_000

# Get the current time for timestamps
current_time = Time.current

puts "Starting follow relationship generation..."

# Define the target number of followings for EACH of the first 100,000 users.
#
# WARNING: Setting this to 500,000 followings PER USER for 100,000 users
# will result in a total of 50,000,000,000 (50 billion) follow relationships.
# This is an extremely large number and will likely be unfeasible for most databases.
# It will consume massive amounts of time, memory, and storage.
# Please consider reducing this number significantly if this is not your exact intent.
target_followings_per_user = 100_000

# Fetch IDs of users who will be followers (first 100,000)
# Using `pluck(:id)` is efficient for getting just the IDs
follower_user_ids = User.order(:id).limit(100_000).pluck(:id)
if follower_user_ids.empty?
  puts "No users found to create follow relationships. Please run db:generate_million_users first."
  exit
end

# Fetch IDs of all users (potential targets for following)
all_user_ids = User.pluck(:id)
if all_user_ids.empty?
  puts "No target users found. Please run db:generate_million_users first."
  exit
end

generated_total_follows_count = 0
total_expected_follows = follower_user_ids.size * target_followings_per_user

puts "\n"
puts "################################################################################"
puts "### ATTENTION: MASSIVE DATA GENERATION WARNING!                              ###"
puts "################################################################################"
puts "### You are attempting to generate a total of #{total_expected_follows} follow relationships. ###"
puts "### This means each of the #{follower_user_ids.size} designated follower users will attempt ###"
puts "### to gain #{target_followings_per_user} followings.                          ###"
puts "###                                                                          ###"
puts "### This operation is expected to be EXTREMELY time-consuming and may      ###"
puts "### exhaust system resources or database capacity.                           ###"
puts "### Proceed with caution, and consider reducing 'target_followings_per_user' ###"
puts "### if this is not the desired scale.                                        ###"
puts "################################################################################"
puts "\n"


# Loop through each of the first 100,000 follower users
follower_user_ids.each_with_index do |follower_id, index|
  puts "Generating follows for user ID: #{follower_id} (Follower #{index + 1}/#{follower_user_ids.size})..."
  current_user_follows_count = 0 # Counter for follows generated for the current user

  # Calculate the number of batches needed for the current user
  num_batches_for_user = target_followings_per_user / batch_size

  # Loop to generate follows for the current user in batches
  num_batches_for_user.times do |batch_index|
    follows_data = []
    batch_size.times do
      # Randomly select a target from all available users
      target_id = all_user_ids.sample

      # Ensure a user does not follow themselves; re-sample if necessary
      while follower_id == target_id
        target_id = all_user_ids.sample
      end

      # Add the new follow relationship to the batch data
      follows_data << {
        user_id: follower_id,
        target_user_id: target_id,
        created_at: current_time,
        updated_at: current_time
      }
    end

    # Perform the bulk insert for the current batch
    begin
      # `on_duplicate: :ignore` ensures that if the same (user_id, target_user_id)
      # pair is generated multiple times (e.g., if a user randomly selects to follow
      # the same person twice), only the first one is inserted, preventing unique
      # constraint violations.
      Follow.insert_all(follows_data)

      # Update counters
      current_user_follows_count += batch_size
      generated_total_follows_count += batch_size

      # Provide progress update for the current user and total
      puts "  User #{follower_id}: Generated #{current_user_follows_count} / #{target_followings_per_user} follows. (Batch #{batch_index + 1}/#{num_batches_for_user}). Total relationships generated: #{generated_total_follows_count}"
    rescue => e
      # Log any errors during batch insertion
      puts "  Error inserting batch for user #{follower_id}: #{e.message}"
    end
  end

  # Handle any remaining follows for the current user if 'target_followings_per_user'
  # is not perfectly divisible by 'batch_size'
  remaining_follows_for_user = target_followings_per_user % batch_size
  if remaining_follows_for_user > 0
    follows_data = []
    remaining_follows_for_user.times do
      target_id = all_user_ids.sample
      while follower_id == target_id
        target_id = all_user_ids.sample
      end
      follows_data << {
        user_id: follower_id,
        target_user_id: target_id,
        created_at: current_time,
        updated_at: current_time
      }
    end
    begin
      Follow.insert_all(follows_data, on_duplicate: :ignore)
      current_user_follows_count += remaining_follows_for_user
      generated_total_follows_count += remaining_follows_for_user
      puts "  User #{follower_id}: Generated #{current_user_follows_count} / #{target_followings_per_user} follows (final batch for user). Total relationships generated: #{generated_total_follows_count}"
    rescue => e
      puts "  Error inserting final batch for user #{follower_id}: #{e.message}"
    end
  end
  puts "Finished generating follows for user ID: #{follower_id}. Total relationships for this user: #{current_user_follows_count}."
  puts "Approximate total relationships generated so far: #{generated_total_follows_count}."
end

puts "\n"
puts "Follow relationship generation complete. A total of #{generated_total_follows_count} relationships were attempted."
puts "Note: Some relationships might have been ignored due to duplicates or self-follows."
