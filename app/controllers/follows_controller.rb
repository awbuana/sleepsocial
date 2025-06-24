class FollowsController < ApplicationController
  before_action :set_follow, only: %i[ show ]
  before_action :authenticate!, only: %i[ create destroy ]

  # GET /follows
  def index
    scope = if params[:user_id]
      Follow.where(user_id: params[:user_id])
    elsif current_user.present?
      Follow.where(user_id: current_user.id)
    else
      Follow.all.order(id: :desc)
    end

    paginator = scope.preload(:user, :target_user).cursor_paginate(**pagination_params)
    page = paginator.fetch

    render_serializer page.records, FollowSerializer, meta: {
      prev_cursor: page.previous_cursor,
      next_cursor: page.next_cursor
    }
  end

  # GET /follows/1
  def show
    render_serializer @follow, FollowSerializer
  end

  # POST /follows
  def create
    @follow = FollowService.follow(current_user, follow_params[:target_user_id])

    render_serializer @follow, FollowSerializer, status: :created
  end

  # DELETE /follows
  def destroy
    FollowService.unfollow(current_user, follow_params[:target_user_id])

    render_message "Unfollow successfully"
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_follow
    @follow = Follow.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def follow_params
    @follow_params ||= params.expect(follow: [ :target_user_id ])
  end
end
