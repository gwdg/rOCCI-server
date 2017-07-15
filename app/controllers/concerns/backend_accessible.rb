module BackendAccessible
  extend ActiveSupport::Concern

  # Returns and caches instance of the `BackendProxy` class.
  #
  # @return [BackendProxy] instance of the `BackendProxy` class
  def backend_proxy
    return @_backend_proxy if @_backend_proxy

    backend_type = app_config.fetch('backend')
    logger.debug "Starting backend proxy for #{backend_type}"
    @_backend_proxy = BackendProxy.new(
      type: backend_type.to_sym,
      options: app_config.fetch(backend_type, {}),
      logger: logger
    )
  end

  # Returns backend instance of the given subtype.
  #
  # @example
  #    backend_proxy_for 'compute' # => #<Compute ...>
  #
  # @param subtype [String] backend subtype
  # @return [Entitylike, Extenderlike] subtype instance
  def backend_proxy_for(subtype)
    raise "#{subtype.inspect} is not a supported backend subtype" unless backend_proxy.has?(subtype.to_sym)
    backend_proxy.send subtype
  end
end
