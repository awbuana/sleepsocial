class ApplicationController < ActionController::API
  include ErrorHandling

  def current_user
    return @current_user if defined?(@current_user)

    user_id = request.headers["X-USER-ID"]

    @current_user = if user_id.present?
      User.find(user_id)
    else
      nil
    end
  end

  def authenticate!
    raise Sleepsocial::UnauthenticatedError.new("User must be login") unless current_user
  end

  def render_serializer(resource, serializer, **options)
    if resource.kind_of?(Array)
      serializable = ActiveModelSerializers::SerializableResource.new(resource, each_serializer: serializer, root: :data, **options).to_json

      render json: serializable
    else
      options.merge!(json: resource, root: :data)
      options.merge!(status: :ok) unless options.key?(:status)

      render options
    end
  end

  def render_message(message, **options)
    options.merge!(json: { message: message }.to_json)
    options.merge!(status: :ok) unless options.key?(:status)

    render options
  end

  def render_error(errors, status = :unprocessable_entity)
    render json: errors, status: status, root: :errors
  end

  def pagination_params
    permitted = params.permit(:limit, :after, :before).to_h.symbolize_keys
    permitted[:limit] = permitted[:limit].to_i if permitted[:limit]

    pagination_params = permitted
    pagination_params.merge!(order: { id: :desc })
    pagination_params
  end
end
