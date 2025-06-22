class TimelinesController < ApplicationController
  before_action :set_current_user, only: %i[ index ]

  # GET /timelines
  def index
    logs = TimelineService.precomputed_feed(@current_user)

    render_serializer logs, SleepLogSerializer
  end


  private

  def index_params
    index_params ||= params.permit(:user_id, :limit, :offset)
  end

  def set_current_user
    @current_user ||= User.find(index_params[:user_id])
  end
end
