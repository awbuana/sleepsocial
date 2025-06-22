class SleepLogsController < ApplicationController
  before_action :set_sleep_log, only: %i[ show clock_out ]

  # GET /sleep_logs
  def index
    permitted = params.permit(:limit, :after, :before).to_h.symbolize_keys
    permitted[:limit] = permitted[:limit].to_i if permitted[:limit]

    paginator = SleepLog.all.cursor_paginate(**permitted)
    page = paginator.fetch

    render json: ActiveModelSerializers::SerializableResource.new(page.records, each_serializer: SleepLogSerializer, meta: {
      prev_cursor: page.previous_cursor,
      next_cursor: page.next_cursor
    }).to_json
  end

  # GET /sleep_logs/1
  def show
    render json: @sleep_log
  end

  # POST /sleep_logs
  def create
    @sleep_log = SleepLog.new(sleep_log_params)

    if @sleep_log.save
      render json: @sleep_log, status: :created, location: @sleep_log
    else
      render json: @sleep_log.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /sleep_logs/1/clock-out
  def clock_out
    raise Sleepsocial::ValidationError.new("User already clocked out") if @sleep_log.clock_out

    if @sleep_log.update(clock_out: Time.now)
      render json: @sleep_log, serializer: SleepLogSerializer
    else
      render json: @sleep_log.errors, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_sleep_log
    @sleep_log = SleepLog.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def sleep_log_params
    params.expect(sleep_log: [ :user_id ])
  end

  def update_sleep_log_params
    params.expect(sleep_log: [ :clock_out ])
  end
end
