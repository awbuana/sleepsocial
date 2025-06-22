class FollowsController < ApplicationController
  before_action :set_follow, only: %i[ show ]

  # GET /follows
  def index
    permitted = params.permit(:user_id, :limit, :after, :before).to_h.symbolize_keys
    permitted[:limit] = permitted[:limit].to_i if permitted[:limit]
    raise Sleepsocial::Error.("Parameter user_id is missing") unless permitted[:user_id]

    pagination_params = permitted.slice(:limit, :after, :before)
    paginator = Follow.where(user_id: permitted[:user_id]).cursor_paginate(**pagination_params)
    page = paginator.fetch

    render_serializer page.records, FollowSerializer, meta: {
      prev_cursor: page.previous_cursor,
      next_cursor: page.next_cursor
    }
  end

  # GET /follows/1
  def show
    render json: @follow
  end

  # POST /follows
  def create
    @user = User.find(follow_params[:user_id])
    @follow = FollowService.follow(@user, follow_params[:target_user_id])

    render json: @follow, status: :created
  end

  # DELETE /follows
  def destroy
    @user = User.find(follow_params[:user_id])
    FollowService.unfollow(@user, follow_params[:target_user_id])

    render_message "Unfollow successfully"
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_follow
    @follow = Follow.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def follow_params
    @follow_params ||= params.expect(follow: [ :user_id, :target_user_id ])
  end
end
