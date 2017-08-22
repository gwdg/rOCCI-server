module BackendAccessible
  # Returns and caches instance of the `BackendProxy` class.
  #
  # @param with_model [TrueClass, FalseClass] whether to include `server_model` reference
  # @return [BackendProxy] instance of the `BackendProxy` class
  def backend_proxy(with_model = true)
    return @_backend_proxy if @_backend_proxy

    backend_type = app_config.fetch('backend')
    logger.debug "Starting backend proxy for #{backend_type}"
    @_backend_proxy = BackendProxy.new(
      type: backend_type.to_sym, options: app_config.fetch(backend_type, {}),
      logger: logger, credentials: backend_credentials
    )
    @_backend_proxy.server_model = server_model if with_model

    @_backend_proxy
  end

  # Returns backend instance of the given subtype.
  #
  # @example
  #    backend_proxy_for 'compute' # => #<Compute ...>
  #
  # @param subtype [String] backend subtype
  # @return [Entitylike, Extenderlike] subtype instance
  def backend_proxy_for(subtype)
    unless backend_proxy.has?(subtype.to_sym)
      raise Errors::BackendForbiddenError, "#{subtype} is not a supported backend subtype"
    end
    with_model = (subtype != 'model_extender')
    backend_proxy(with_model).send subtype
  end

  # Returns backend credentials for the current context/request.
  #
  # @return [Hash] credentials in a Hash
  def backend_credentials
    { user_id: current_user, secret_key: current_token }
  end
end
