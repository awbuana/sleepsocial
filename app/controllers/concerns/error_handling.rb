# frozen_string_literal: true

module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from Sleepsocial::UnauthenticatedError do |e|
      render json: { error: e.message }, status: 401
    end

    rescue_from ActiveRecord::RecordInvalid, BaseService::ServiceError do |e|
      render json: { error: e.message }, status: 422
    end

    rescue_from ActiveRecord::RecordNotUnique do
      render json: { error: "Duplicate record" }, status: 422
    end

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "Record not found" }, status: 404
    end

    rescue_from ActionController::ParameterMissing do |e|
      render json: { error: e.message }, status: 400
    end

    # rescue_from StandardError do |e|
    #   render json: { error: "Internal Server Error" }, status: 500
    # end
  end
end
