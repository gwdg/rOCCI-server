module Mixins
  module ErrorHandling
    # Define handlers for known exceptions
    def handle_parser_type_err(exception)
      logger.warn "[Parser] Request from #{request.remote_ip} refused with: #{exception.message}"
      render text: exception.message, status: 406
    end

    def handle_parser_input_err(exception)
      logger.warn "[Parser] Request from #{request.remote_ip} refused with: #{exception.message}"
      render text: exception.message, status: 400
    end

    def handle_not_impl_err(exception)
      logger.error "[Backend] Active backend does not implement requested method: #{exception.message}"
      render text: exception.message, status: 501
    end

    def handle_wrong_args_err(exception)
      logger.warn "[Backend] User did not provide necessary arguments to execute an action: #{exception.message}"
      render text: exception.message, status: 400
    end

    def handle_invalid_resource_err(exception)
      logger.warn "[Backend] User did not provide a valid resource instance: #{exception.message}"
      render text: exception.message, status: 409
    end

    def handle_resource_not_found_err(exception)
      logger.warn "[Backend] User referenced a non-existent resource instance: #{exception.message}"
      render text: exception.message, status: 404
    end

    def handle_internal_backend_err(exception)
      logger.error "[Backend] Failed to execute a backend routine: #{exception.message}"
      render text: exception.message, status: 500
    end

    def handle_auth_err(exception)
      logger.warn "[Backend] Failed to authenticate user: #{exception.message}"
      render text: exception.message, status: 401
    end

    def handle_authz_err(exception)
      logger.warn "[Backend] Failed to authorize user: #{exception.message}"
      render text: exception.message, status: 403
    end
  end
end
