module TimelineService
  class PrecomputedFeed < TimelineService::Base
    def initialize(user, options = {})
      @user = user
      @limit = (options[:limit] || 20).to_i
      @offset = (options[:offset] || 0).to_i
    end

    def perform
      user_feed = UserFeed.new(@user)

      logs = user_feed.feed(@offset, @limit)
      deprecated_logs = remove_deprecated_logs(user_feed, logs)
      filter_log_ids = filter_log_ids(logs, deprecated_logs)

      sleep_logs = SleepLog.fetch_multi(filter_log_ids, includes: :user)
      {
        data: sleep_logs.sort_by { |log| [ log.sleep_duration, log.id ] }.reverse,
        limit: @limit,
        offset: @offset,
      }
    end

    private

    def remove_deprecated_logs(user_feed, logs)
      deprecated_logs = logs.select do |log|
        log.created_at < timeline_threshold
      end

      user_feed.remove_from_feed(deprecated_logs) if deprecated_logs.present?

      deprecated_logs
    end

    def filter_log_ids(logs, deprecated_logs)
      deprecated_keys = deprecated_logs.map { |log| log.id }.to_set
      logs.reject! { |log| deprecated_keys.include?(log.id) }

      logs.map { |log| log.id }
    end
  end
end
