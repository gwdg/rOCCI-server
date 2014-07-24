# A set of mixins for rOCCI-server's controllers. Includes
# various helpers and handling methods shared among controllers
# or stuff off-loaded during controller refactoring.
module Mixins
  # A set of error handling methods responding to various
  # errors raised by the server and its backends. These are designed
  # to work with the `rescue_from` method.
  module ErrorHandling
    # Handler responding with HTTP 406 and the exception message.
    #
    # @param exception [Exception] exception to convert into a response
    def handle_parser_type_err(exception)
      logger.warn "[Parser] Request from #{request.remote_ip} refused with: #{exception.message}"
      render text: exception.message, status: 406
    end

    # Handler responding with HTTP 400 and the exception message.
    #
    # @param exception [Exception] exception to convert into a response
    def handle_parser_input_err(exception)
      logger.warn "[Parser] Request from #{request.remote_ip} refused with: #{exception.message}"
      render text: exception.message, status: 400
    end

    # Handler responding with HTTP 501 and the exception message.
    #
    # @param exception [Exception] exception to convert into a response
    def handle_not_impl_err(exception)
      logger.error "[Backend] Active backend does not implement requested method: #{exception.message}"
      render text: exception.message, status: 501
    end

    # Handler responding with HTTP 400 and the exception message.
    #
    # @param exception [Exception] exception to convert into a response
    def handle_wrong_args_err(exception)
      logger.warn "[Backend] User did not provide necessary arguments to execute an action: #{exception.message}"
      render text: exception.message, status: 400
    end

    # Handler responding with HTTP 409 and the exception message.
    #
    # @param exception [Exception] exception to convert into a response
    def handle_invalid_resource_err(exception)
      logger.warn "[Backend] User did not provide a valid resource instance: #{exception.message}"
      render text: exception.message, status: 409
    end

    # Handler responding with HTTP 404 and the exception message.
    #
    # @param exception [Exception] exception to convert into a response
    def handle_resource_not_found_err(exception)
      logger.warn "[Backend] User referenced a non-existent resource instance: #{exception.message}"
      render text: exception.message, status: 404
    end

    # Handler responding with HTTP 500 and the exception message.
    #
    # @param exception [Exception] exception to convert into a response
    def handle_internal_backend_err(exception)
      logger.error "[Backend] Failed to execute a backend routine: #{exception.message}"
      render text: exception.message, status: 500
    end

    # Handler responding with HTTP 503 and the exception message.
    #
    # @param exception [Exception] exception to convert into a response
    def handle_backend_unavailable_err(exception)
      logger.error "[Backend] Failed to connect to the underlying CMF: #{exception.message}"
      render text: exception.message, status: 503
    end

    # Handler responding with HTTP 401 and the exception message.
    #
    # @param exception [Exception] exception to convert into a response
    def handle_auth_err(exception)
      logger.warn "[Backend] Failed to authenticate user: #{exception.message}"
      render text: exception.message, status: 401
    end

    # Handler responding with HTTP 403 and the exception message.
    #
    # @param exception [Exception] exception to convert into a response
    def handle_authz_err(exception)
      logger.warn "[Backend] Failed to authorize user: #{exception.message}"
      render text: exception.message, status: 403
    end
  end
end
