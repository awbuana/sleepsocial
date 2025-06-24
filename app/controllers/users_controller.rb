class UsersController < ApplicationController
  before_action :set_user, only: %i[ show following followers ]

  # GET /users
  def index
    paginator = User.all.cursor_paginate(**pagination_params)
    page = paginator.fetch

    render_serializer page.records, UserSerializer, meta: {
      prev_cursor: page.previous_cursor,
      next_cursor: page.next_cursor
    }
  end

  # GET /users/1
  def show
    render_serializer @user, UserSerializer
  end

  # POST /users
  def create
    @user = User.new(user_params)
    @user.save!

    render_serializer @user, UserSerializer, status: :created
  end

  # GET /users/1/following
  def following
    paginator = @user.following.all.cursor_paginate(**pagination_params)
    page = paginator.fetch

    render_serializer page.records, UserSerializer, meta: {
      prev_cursor: page.previous_cursor,
      next_cursor: page.next_cursor
    }
  end

  # GET /users/1/followers
  def followers
    paginator = @user.followers.all.cursor_paginate(**pagination_params)
     page = paginator.fetch

    render_serializer page.records, UserSerializer, meta: {
      prev_cursor: page.previous_cursor,
      next_cursor: page.next_cursor
    }
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
