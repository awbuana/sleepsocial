class LeaderboardsController < ApplicationController
  before_action :authenticate!

  # GET /leaderboards
  def index
    feed = LeaderboardService.precomputed_feed(@current_user, limit: params[:limit], offset: params[:offset])

    render_serializer feed[:data], SleepLogSerializer, meta: { offset: feed[:offset], limit: feed[:limit], count: feed[:count] }
  end
end
