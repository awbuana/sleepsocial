module TimelineService
  class Base < ::BaseService
    def timeline_threshold
      7.days.ago
    end
  end
end
