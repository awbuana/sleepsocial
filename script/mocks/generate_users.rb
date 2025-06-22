require_relative "../../config/environment"

# --- Configuration ---
NUM_USERS = 1000
MAX_FOLLOWS_PER_USER = 500

puts "Generating #{NUM_USERS} users and follow relationships using ActiveRecord..."

user_ids = []

# Generate Users
puts "Creating users..."
NUM_USERS.times do |i|
  begin
    user = User.create!(
      name: Faker::Name.unique.name,
      created_at: Time.now.utc - rand(0..365).days - rand(0..23).hours - rand(0..59).minutes,
      updated_at: Time.now.utc - rand(0..365).days - rand(0..23).hours - rand(0..59).minutes
    )
    user_ids << user.id
    print "." if (i + 1) % 100 == 0 # Progress indicator
  rescue ActiveRecord::RecordInvalid => e
    puts "\nError creating user: #{e.message}"
    retry # Try again with a new unique name if Faker provides a duplicate (unlikely with unique.name)
  end
end
puts "\nUsers created."

# Generate Follows
puts "Creating follow relationships..."
# To ensure unique (user_id, target_user_id) pairs, we'll keep track of generated follows
generated_follows = {} # Format: { user_id => Set[target_user_id], ... }
follow_count = 0

user_ids.each_with_index do |user_id, index|
  num_follows = rand(0..MAX_FOLLOWS_PER_USER)

  # Get potential target user IDs, excluding the current user_id
  possible_target_ids = user_ids - [user_id]

  # If there are not enough possible targets, follow fewer users
  num_follows = [num_follows, possible_target_ids.length].min

  # Shuffle and pick target users
  selected_target_ids = possible_target_ids.shuffle.take(num_follows)

  selected_target_ids.each do |target_user_id|
    # Check for uniqueness using the Set before attempting to create the record
    generated_follows[user_id] ||= Set.new

    unless generated_follows[user_id].include?(target_user_id)
      begin
        Follow.create!(
          user_id: user_id,
          target_user_id: target_user_id,
          created_at: Time.now.utc - rand(0..365).days - rand(0..23).hours - rand(0..59).minutes,
          updated_at: Time.now.utc - rand(0..365).days - rand(0..23).hours - rand(0..59).minutes
        )
        generated_follows[user_id] << target_user_id
        follow_count += 1
      rescue ActiveRecord::RecordInvalid => e
        puts "\nWarning: Could not create follow (user_id: #{user_id}, target_user_id: #{target_user_id}) - #{e.message}"
      rescue ActiveRecord::RecordNotUnique
        puts "\nWarning: Duplicate follow detected and skipped (user_id: #{user_id}, target_user_id: #{target_user_id})."
      end
    end
  end
  print "." if (index + 1) % 100 == 0 # Progress indicator
end

puts "\nFollow relationships created."

puts "Mock data generation complete!"
puts "Total users created: #{User.count}"
puts "Total follow relationships created: #{Follow.count}"

