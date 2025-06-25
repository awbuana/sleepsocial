module LeaderboardService
  class Base < ::BaseService
    def leaderboard_threshold
      ENV.fetch("LEADERBOARD_DATE_THRESHOLD_IN_DAYS", 7).to_i.days.ago
    end
  end
end
