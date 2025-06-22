class SleepLogsController < ApplicationController
  before_action :set_sleep_log, only: %i[ show clock_out ]

  # GET /sleep_logs
  def index
    permitted = params.permit(:limit, :after, :before).to_h.symbolize_keys
    permitted[:limit] = permitted[:limit].to_i if permitted[:limit]

    paginator = SleepLog.all.cursor_paginate(**permitted)
    page = paginator.fetch

    render_serializer page.records, SleepLogSerializer, meta: {
      prev_cursor: page.previous_cursor,
      next_cursor: page.next_cursor
    }
  end

  # GET /sleep_logs/1
  def show
    render_serializer @sleep_log, SleepLogSerializer
  end

  # POST /sleep_logs
  def create
    @sleep_log = SleepLogService.create_log(current_user)
    render_serializer @sleep_log, SleepLogSerializer, status: :created
  end

  # PATCH/PUT /sleep_logs/1/clock-out
  def clock_out
    raise Sleepsocial::ValidationError.new("User already clocked out") if @sleep_log.clock_out

    @sleep_log.update!(clock_out: Time.now)

    render_serializer @sleep_log, SleepLogSerializer
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_sleep_log
    @sleep_log = SleepLog.find(params.expect(:id))
  end

  def update_sleep_log_params
    params.expect(sleep_log: [ :clock_out ])
  end

  def current_user
    raise Sleepsocial::NotPermittedError.new("user_id must be present") unless params[:user_id]

    @current_user ||= User.find(params[:user_id])
  end
end
