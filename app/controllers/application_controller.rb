class ApplicationController < ActionController::API
  private

  # Render a single resource
  def render_resource(resource, serializer:, status: :ok, meta: nil, serializer_method: :as_json)
    data = serializer.new(resource).public_send(serializer_method)
    response_body = { data: data }
    response_body[:meta] = meta if meta.present?

    render json: response_body, status: status
  end

  # Render a collection of resources
  def render_collection(resources, serializer:, status: :ok, meta: nil)
    data = resources.map { |resource| serializer.new(resource).as_json }
    response_body = { data: data }
    response_body[:meta] = meta if meta.present?

    render json: response_body, status: status
  end

  # Render error response
  def render_error(message, status: :unprocessable_entity, details: nil)
    error_body = { error: { message: message } }
    error_body[:error][:details] = details if details.present?

    render json: error_body, status: status
  end
end
