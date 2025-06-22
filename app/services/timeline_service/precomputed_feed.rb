module TimelineService
  class PrecomputedFeed < ::BaseService

    def initialize(account, options = {})
      @account = account
    end

    def perform
      records = []

      @account.following.find_in_batches do |following|
        records << SleepLog.where(user_id: following).to_a
      end

      records.flatten
    end

  end
end