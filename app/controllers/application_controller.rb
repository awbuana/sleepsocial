class ApplicationController < ActionController::API
  include ErrorHandling

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

  def render_error(errors, status = :unprocessable_entity)
    render json: errors, status: status, root: :errors
  end
end
