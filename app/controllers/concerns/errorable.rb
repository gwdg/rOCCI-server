module Errorable
  extend ActiveSupport::Concern

  included do
    rescue_from Errors::Backend::AuthorizationError, with: :handle_authorization_error
  end

  # Converts a numeric code and message into a valid Rails reponse.
  # Response is automatically sent via `respond_with` to the client.
  #
  # @param code [Numeric] reponse code (HTTP code)
  # @param message [String] response message
  def render_error(code, message)
    respond_with Ext::RenderableError.new(code, message), status: code
  end

  # Handles authorization errors and responds with appropriate HTTP code and headers.
  def handle_authorization_error
    response.headers[self.class.redirect_header_key] = self.class.redirect_header_uri
    render_error 401, 'Not Authorized'
  end
end
