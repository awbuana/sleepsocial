class UsersController < ApplicationController
  before_action :set_user, only: %i[ show destroy ]

  # GET /users
  def index
    permitted = params.permit(:limit, :after, :before).to_h.symbolize_keys
    permitted[:limit] = permitted[:limit].to_i if permitted[:limit]

    paginator = User.all.cursor_paginate(**permitted)
    page = paginator.fetch

    render_serializer page.records UserSerializer, meta: {
      prev_cursor: page.previous_cursor,
      next_cursor: page.next_cursor
    }
  end

  # GET /users/1
  def show
    render json: @user
  end

  # POST /users
  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, status: :created, location: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy!
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.expect(user: [ :name ])
  end
end
