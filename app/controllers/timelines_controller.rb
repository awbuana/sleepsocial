class TimelinesController < ApplicationController
  before_action :authenticate!

  # GET /timelines
  def index
    feed = TimelineService.precomputed_feed(@current_user, limit: params[:limit], offset: params[:offset])

    render_serializer feed[:data], SleepLogSerializer, meta: { offset: feed[:offset], limit: feed[:limit]}
  end
end
