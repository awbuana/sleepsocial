class SleepLogsController < ApplicationController
  before_action :set_sleep_log, only: %i[ show clock_out ]
  before_action :authenticate!, only: %i[ create clock_out ]

  # GET /sleep_logs
  def index
    scope =  if params[:user_id]
      SleepLog.where(user_id: params[:user_id])
    elsif current_user.present?
      SleepLog.where(user_id: current_user.id)
    else
      SleepLog.all.preload(:user)
    end

    paginator = scope.preload(:user).cursor_paginate(**pagination_params)
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
end
