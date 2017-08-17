module Errorable
  extend ActiveSupport::Concern

  KNOWN_ERRORS = {
    Errors::ParsingError => { with: :parsing_error },
    Errors::ValidationError => { with: :validation_error },
    Errors::BackendForbiddenError => { with: :forbidden_error },
    Errors::Backend::ConnectionError => { with: :connection_error },
    Errors::Backend::AuthenticationError => { with: :authorization_error },
    Errors::Backend::AuthorizationError => { with: :authorization_error },
    Errors::Backend::NotImplementedError => { with: :not_implemented_error }
  }.freeze

  included do
    KNOWN_ERRORS.each_pair { |klass, hndl| rescue_from(klass, hndl) }
  end

  # Converts a sybolized code and message into a valid Rails reponse.
  # Response is automatically sent via `respond_with` to the client.
  #
  # @param code [Symbol] reponse code (HTTP code as a symbol used in Rails)
  # @param message [String] response message
  def render_error(code, message)
    respond_with Ext::RenderableError.new(code, message), status: code
  end

  # Handles authorization errors and responds with appropriate HTTP code and headers.
  #
  # @param exception [Exception] exception to convert into a response
  def authorization_error(exception)
    log_message! exception
    response.headers[self.class.redirect_header_key] = self.class.redirect_header_uri
    render_error :unauthorized, 'Not Authorized'
  end

  # Handles parsing errors and responds with appropriate HTTP code and headers.
  #
  # @param exception [Exception] exception to convert into a response
  def parsing_error(exception)
    log_message! exception
    render_error :bad_request, "Unparsable content: #{exception}"
  end

  # Handles validation errors and responds with appropriate HTTP code and headers.
  #
  # @param exception [Exception] exception to convert into a response
  def validation_error(exception)
    log_message! exception
    render_error :bad_request, "Invalid content: #{exception}"
  end

  # Handles connection errors and responds with appropriate HTTP code and headers.
  #
  # @param exception [Exception] exception to convert into a response
  def connection_error(exception)
    log_message! exception, :fatal
    render_error :service_unavailable, 'Cloud platform is temporarily unavailable'
  end

  # Handles functionality that is not implemented and responds with appropriate HTTP code and headers.
  #
  # @param exception [Exception] exception to convert into a response
  def not_implemented_error(exception)
    log_message! exception, :info
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # Handles functionality that is not allowed and responds with appropriate HTTP code and headers.
  #
  # @param exception [Exception] exception to convert into a response
  def forbidden_error(exception)
    log_message! exception
    render_error :forbidden, 'Requested functionality is not allowed'
  end

  # :nodoc:
  def log_message!(exception, level = :error)
    logger.send level, "#{exception.class}: #{exception}"
  end
end
