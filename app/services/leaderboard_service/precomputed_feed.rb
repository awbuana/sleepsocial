module LeaderboardService
  class PrecomputedFeed < LeaderboardService::Base
    GET_FEED_LIMIT_BUFFER = 100

    def initialize(user, options = {})
      @user = user
      @limit = (options[:limit] || 20).to_i
      @offset = (options[:offset] || 0).to_i
    end

    def perform
      user_feed = UserFeed.new(@user)

      # get feeds with buffer
      # lazily delete expired logs from redis if any
      logs = user_feed.feed(@offset, @limit+GET_FEED_LIMIT_BUFFER)
      expired_logs = remove_expired_logs(user_feed, logs)
      filtered_log_ids = filter_log_ids(logs, expired_logs).take(@limit)

      sleep_logs = SleepLog.fetch_multi(filtered_log_ids, includes: :user)
      {
        data: sleep_logs.sort_by { |log| [ log.sleep_duration, log.id ] }.reverse,
        limit: @limit,
        offset: @offset
      }
    end

    private

    def remove_expired_logs(user_feed, logs)
      expired_logs = logs.select do |log|
        log.clock_in < leaderboard_threshold
      end

      user_feed.remove_from_feed(expired_logs) if expired_logs.present?

      expired_logs
    end

    def filter_log_ids(logs, expired_logs)
      expired_keys = expired_logs.map { |log| log.id }.to_set
      logs.reject! { |log| expired_keys.include?(log.id) }

      logs.map { |log| log.id }
    end
  end
end
