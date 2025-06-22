class SleepLogsController < ApplicationController
  before_action :set_sleep_log, only: %i[ show clock_out ]
  before_action :authenticate!, only: %i[ create clock_out ]

  # GET /sleep_logs
  def index
    permitted = params.permit(:limit, :after, :before).to_h.symbolize_keys
    permitted[:limit] = permitted[:limit].to_i if permitted[:limit]

    paginator =  if current_user
      SleepLog.where(user_id: current_user.id).cursor_paginate(**permitted)
    else
      SleepLog.all.cursor_paginate(**permitted)
    end

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
    @sleep_log = SleepLogService.create_log(current_user, params.permit(:clock_in, :clock_out))
    render_serializer @sleep_log, SleepLogSerializer, status: :created
  end

  # PATCH/PUT /sleep_logs/1/clock-out
  def clock_out
    SleepLogService.clock_out(current_user, @sleep_log, params[:clock_out])
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
end
