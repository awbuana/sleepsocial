require 'rails_helper'

RSpec.describe UserFeed, type: :model do
  # Use `let!` to ensure the user object is created for each example.
  let!(:user) { create(:user, id: 123) }
  # Instantiate the UserFeed object for each test.
  let(:user_feed) { UserFeed.new(user) }

  # Mock the global REDIS constant. This is crucial to avoid actual Redis calls.
  # We use `allow(REDIS).to receive(:call)` to mock specific Redis commands.
  before do
    allow(REDIS).to receive(:call) # Allow all calls to REDIS.call by default
  end

  # Helper for creating a mock sleep log with necessary attributes.
  # This avoids creating actual database records for SleepLog.
  def mock_sleep_log(id, user_id, clock_in, sleep_duration)
    instance_double("SleepLog",
                    id: id,
                    user_id: user_id,
                    clock_in: clock_in,
                    sleep_duration: sleep_duration)
  end

  describe '#initialize' do
    it 'sets the user instance variable' do
      expect(user_feed.instance_variable_get(:@user)).to eq(user)
    end
  end

  describe '#feed' do
    let(:feed_key) { "feed:#{user.id}" }
    let(:clock_in_time_1) { Time.zone.parse("2024-06-25 10:00:00 UTC") }
    let(:clock_in_time_2) { Time.zone.parse("2024-06-25 09:00:00 UTC") }

    # Sample JSON strings representing members in Redis.
    let(:redis_member_json_1) { { uid: 456, id: 1, ts: clock_in_time_1.strftime("%Y%m%dT%H%M%S%z") }.to_json }
    let(:redis_member_json_2) { { uid: 789, id: 2, ts: clock_in_time_2.strftime("%Y%m%dT%H%M%S%z") }.to_json }

    before do
      # Mock ZRANGE to return our sample JSON strings.
      allow(REDIS).to receive(:call).with("ZRANGE", feed_key, 0, -1, "REV")
                                     .and_return([ redis_member_json_1, redis_member_json_2 ])
      allow(REDIS).to receive(:call).with("ZRANGE", feed_key, 0, 0, "REV") # for limit 1
                                     .and_return([ redis_member_json_1 ])
      allow(REDIS).to receive(:call).with("ZRANGE", feed_key, 1, 1, "REV") # for offset 1, limit 1
                                     .and_return([ redis_member_json_2 ])
    end

    it 'calls ZRANGE on Redis with correct key and range for default params' do
      user_feed.feed
      expect(REDIS).to have_received(:call).with("ZRANGE", feed_key, 0, -1, "REV")
    end

    it 'calls ZRANGE on Redis with correct key, offset, and limit' do
      user_feed.feed(0, 1)
      expect(REDIS).to have_received(:call).with("ZRANGE", feed_key, 0, 0, "REV")
    end

    it 'calls ZRANGE on Redis with correct key, offset, and limit when both are provided' do
      user_feed.feed(1, 1)
      expect(REDIS).to have_received(:call).with("ZRANGE", feed_key, 1, 1, "REV")
    end

    it 'parses and returns UserFeed::Member objects' do
      members = user_feed.feed
      expect(members.first).to be_a(UserFeed::Member)
      expect(members.first.id).to eq(1)
      expect(members.first.user_id).to eq(456)
      expect(members.first.clock_in.to_i).to eq(clock_in_time_1.to_i) # Compare as integer timestamps
      expect(members.last.id).to eq(2)
    end

    it 'returns an empty array if Redis returns no members' do
      allow(REDIS).to receive(:call).with("ZRANGE", feed_key, anything, anything, "REV")
                                     .and_return([])
      expect(user_feed.feed).to eq([])
    end
  end

  describe '#count' do
    let(:feed_key) { "feed:#{user.id}" }

    before do
      # Mock ZCARD to return a specific count.
      allow(REDIS).to receive(:call).with("ZCARD", feed_key).and_return(5)
    end

    it 'calls ZCARD on Redis with the correct key' do
      user_feed.count
      expect(REDIS).to have_received(:call).with("ZCARD", feed_key)
    end

    it 'returns the count as an integer' do
      expect(user_feed.count).to eq(5)
    end
  end

  describe '#add_to_feed' do
    let(:feed_key) { "feed:#{user.id}" }
    let(:clock_in_time) { Time.zone.parse("2024-06-25 11:00:00 UTC") }
    let(:sleep_log) { mock_sleep_log(3, 123, clock_in_time, 8.hours.to_i) } # id, user_id, clock_in, sleep_duration

    it 'calls ZADD on Redis with correct key, score, and member_key' do
      expected_score = sleep_log.sleep_duration
      expected_member_key_json = { uid: sleep_log.user_id, id: sleep_log.id, ts: sleep_log.clock_in.strftime("%Y%m%dT%H%M%S%z") }.to_json

      user_feed.add_to_feed(sleep_log)

      expect(REDIS).to have_received(:call).with("ZADD", feed_key, expected_score, expected_member_key_json)
    end
  end

  describe '#remove_from_feed' do
    let(:feed_key) { "feed:#{user.id}" }
    let(:clock_in_time_1) { Time.zone.parse("2024-06-25 10:00:00 UTC") }
    let(:clock_in_time_2) { Time.zone.parse("2024-06-25 09:00:00 UTC") }

    # Create UserFeed::Member objects for removal.
    let(:member_to_remove_1) { UserFeed::Member.new(1, 456, clock_in_time_1) }
    let(:member_to_remove_2) { UserFeed::Member.new(2, 789, clock_in_time_2) }

    # Expected JSON strings for ZREM.
    let(:expected_member_key_json_1) { { uid: 456, id: 1, ts: clock_in_time_1.strftime("%Y%m%dT%H%M%S%z") }.to_json }
    let(:expected_member_key_json_2) { { uid: 789, id: 2, ts: clock_in_time_2.strftime("%Y%m%dT%H%M%S%z") }.to_json }

    it 'calls ZREM on Redis with correct key and member keys' do
      members_to_remove = [ member_to_remove_1, member_to_remove_2 ]
      user_feed.remove_from_feed(members_to_remove)

      expect(REDIS).to have_received(:call).with("ZREM", feed_key, [ expected_member_key_json_1, expected_member_key_json_2 ])
    end

    it 'does not call ZREM if the members array is blank' do
      user_feed.remove_from_feed([])
      expect(REDIS).not_to have_received(:call).with("ZREM", anything, anything)
    end
  end

  describe '#resize_feed' do
    let(:feed_key) { "feed:#{user.id}" }
    let(:max_feed) { UserFeed::MAXIMUM_FEED }

    context 'when members_count is greater than MAXIMUM_FEED' do
      before do
        allow(user_feed).to receive(:count).and_return(max_feed + 10) # Simulate 10 members over limit
      end

      it 'calls ZREMRANGEBYRANK on Redis to remove oldest members' do
        expected_remove_count = (max_feed + 10) - max_feed # 10 members to remove
        user_feed.resize_feed
        expect(REDIS).to have_received(:call).with("ZREMRANGEBYRANK", feed_key, 0, expected_remove_count-1)
      end
    end

    context 'when members_count is equal to MAXIMUM_FEED' do
      before do
        allow(user_feed).to receive(:count).and_return(max_feed)
      end

      it 'does not call ZREMRANGEBYRANK on Redis' do
        user_feed.resize_feed
        expect(REDIS).not_to have_received(:call).with("ZREMRANGEBYRANK", anything, anything, anything)
      end
    end

    context 'when members_count is less than MAXIMUM_FEED' do
      before do
        allow(user_feed).to receive(:count).and_return(max_feed - 10)
      end

      it 'does not call ZREMRANGEBYRANK on Redis' do
        user_feed.resize_feed
        expect(REDIS).not_to have_received(:call).with("ZREMRANGEBYRANK", anything, anything, anything)
      end
    end
  end

  # Test private methods directly
  describe 'private methods' do
    let(:current_time) { Time.zone.parse("2024-06-25 12:30:00 UTC") }

    before do
      Timecop.freeze(current_time) # Freeze time for consistent time formatting
    end

    after do
      Timecop.return
    end

    describe '#feed_key' do
      it 'returns the correct feed key format' do
        expect(user_feed.send(:feed_key)).to eq("feed:#{user.id}")
      end
    end

    describe '#parse_member' do
      let(:json_string) { { uid: 100, id: 50, ts: "20240101T100000+0000" }.to_json }

      it 'parses a JSON string into a UserFeed::Member object' do
        member = user_feed.send(:parse_member, json_string)
        expect(member).to be_a(UserFeed::Member)
        expect(member.id).to eq(50)
        expect(member.user_id).to eq(100)
        expect(member.clock_in).to eq(Time.parse("20240101T100000+0000"))
      end
    end

    describe '#score' do
      let(:sleep_log) { mock_sleep_log(1, 1, Time.current, 7.hours.to_i) } # 7 hours duration

      it 'returns the sleep_duration of the sleep_log' do
        expect(user_feed.send(:score, sleep_log)).to eq(7.hours.to_i)
      end
    end

    describe '#member_key' do
      let(:sleep_log) { mock_sleep_log(200, 300, current_time, 6.hours.to_i) }

      it 'returns a JSON string representing the sleep log member' do
        expected_json = {
          uid: sleep_log.user_id,
          id: sleep_log.id,
          ts: sleep_log.clock_in.strftime("%Y%m%dT%H%M%S%z")
        }.to_json
        expect(user_feed.send(:member_key, sleep_log)).to eq(expected_json)
      end
    end
  end
end
