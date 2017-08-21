module Errorable
  extend ActiveSupport::Concern

  KNOWN_ERRORS = {
    Errors::ParsingError => { with: :parsing_error },
    Errors::ValidationError => { with: :validation_error },
    Errors::BackendForbiddenError => { with: :forbidden_error },
    Errors::Backend::ConnectionError => { with: :connection_error },
    Errors::Backend::AuthenticationError => { with: :authorization_error },
    Errors::Backend::AuthorizationError => { with: :authorization_error },
    Errors::Backend::NotImplementedError => { with: :not_implemented_error },
    Errors::Backend::EntityNotFoundError => { with: :not_found_error },
    Errors::Backend::EntityActionError => { with: :action_error },
    Errors::Backend::EntityCreateError => { with: :create_error },
    Errors::Backend::EntityRetrievalError => { with: :retrieval_error },
    Errors::Backend::EntityStateError => { with: :state_error },
    Errors::Backend::EntityTimeoutError => { with: :timeout_error },
    Errors::Backend::RemoteError => { with: :remote_error }
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

  # @param exception [Exception] exception to convert into a response
  def authorization_error(exception)
    log_message! exception
    response.headers[self.class.redirect_header_key] = self.class.redirect_header_uri
    render_error :unauthorized, 'Not authorized to access requested content'
  end

  # @param exception [Exception] exception to convert into a response
  def parsing_error(exception)
    log_message! exception
    render_error :bad_request, "Unparsable content: #{exception}"
  end

  # @param exception [Exception] exception to convert into a response
  def validation_error(exception)
    log_message! exception
    render_error :conflict, "Invalid content: #{exception}"
  end

  # @param exception [Exception] exception to convert into a response
  def connection_error(exception)
    log_message! exception, :fatal
    render_error :service_unavailable, 'Cloud platform is temporarily unavailable'
  end

  # @param exception [Exception] exception to convert into a response
  def not_implemented_error(exception)
    log_message! exception, :info
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # @param exception [Exception] exception to convert into a response
  def forbidden_error(exception)
    log_message! exception
    render_error :forbidden, 'Requested functionality is not allowed'
  end

  # @param exception [Exception] exception to convert into a response
  def not_found_error(exception)
    log_message! exception
    render_error :not_found, 'Requested entity was not found'
  end

  # @param exception [Exception] exception to convert into a response
  def action_error(exception)
    log_message! exception
    render_error :conflict, "Failed to perform requested change: #{exception}"
  end

  # @param exception [Exception] exception to convert into a response
  def state_error(exception)
    log_message! exception
    render_error :conflict, "State conflict: #{exception}"
  end

  # @param exception [Exception] exception to convert into a response
  def create_error(exception)
    log_message! exception
    render_error :bad_request, "Failed to create requested entity: #{exception}"
  end

  # @param exception [Exception] exception to convert into a response
  def retrieval_error(exception)
    log_message! exception, :fatal
    render_error :internal_server_error, 'Failed to retrieve requested entities'
  end

  # @param exception [Exception] exception to convert into a response
  def timeout_error(exception)
    log_message! exception
    render_error :gateway_timeout, 'Failed to perform requested change in a timely manner'
  end

  # @param exception [Exception] exception to convert into a response
  def remote_error(exception)
    log_message! exception
    render_error :internal_server_error, 'Underlying cloud platform failed to complete request'
  end

  # :nodoc:
  def log_message!(exception, level = :error)
    logger.send level, "#{exception.class}: #{exception}"
  end
end
