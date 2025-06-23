module TimelineService
  class PrecomputedFeed < ::BaseService
    def initialize(user, options = {})
      @user = user
    end

    def perform
      user_feed = UserFeed.new(@user)

      logs = user_feed.feed
      deprecated_logs = remove_deprecated_logs(user_feed, logs)
      filtered_logs = filter_logs(logs, deprecated_logs)

      logs = SleepLog.fetch_multi(filtered_logs, includes: :user)
      logs.sort_by { |log| [log.sleep_duration, log.id] }.reverse
    end

    private

    def remove_deprecated_logs(user_feed, logs)
      deprecated_logs = logs.select do |log|
        _, ts = UserFeed.parse_member(log)
        ts < timeline_threshold
      end

      user_feed.remove_from_feed(deprecated_logs) if deprecated_logs.present?

      deprecated_logs
    end

    def filter_logs(logs, deprecated_logs)
      set_logs = deprecated_logs.to_set
      logs.reject { |log| set_logs.include?(log) }
    end

    def timeline_threshold
      7.days.ago.utc
    end
  end
end
