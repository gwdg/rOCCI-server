class BackendProxy
  # Available backends (supported platforms)
  BACKEND_TYPES = {
    dummy: Backends::Dummy,
    opennebula: Backends::Opennebula
  }.freeze

  # Available backend fragments (supported types of resources)
  BACKEND_RESOURCE_SUBTYPES = %i[
    compute network storage securitygroup ipreservation
  ].freeze

  # Available backend fragments (supported types of links)
  BACKEND_LINK_SUBTYPES = %i[
    storagelink networkinterface securitygrouplink
  ].freeze

  # Available backend fragments (supported types of entities)
  BACKEND_ENTITY_SUBTYPES = [
    BACKEND_RESOURCE_SUBTYPES,
    BACKEND_LINK_SUBTYPES
  ].flatten.freeze

  # Available backend fragments (supported types of non-entities)
  BACKEND_NON_ENTITY_SUBTYPES = %i[model_extender].freeze

  # Available backend fragments (all)
  BACKEND_SUBTYPES = [
    BACKEND_ENTITY_SUBTYPES,
    BACKEND_NON_ENTITY_SUBTYPES
  ].flatten.freeze

  # Required version of the backend API
  API_VERSION = '3.0.0'.freeze

  attr_accessor :type, :options, :logger, :server_model, :credentials

  # Make various static methods available on instances
  DELEG_METHODS = %i[
    api_version can_be? has? entitylike? resourcelike? linklike?
    backend_types backend_subtypes
    backend_resource_subtypes backend_link_subtypes
    backend_entity_subtypes backend_non_entity_subtypes
  ].freeze
  delegate(*DELEG_METHODS, to: :class)

  # Constructs an instance of the backend proxy. This instance can be
  # used to access various backend fragments on demand.
  #
  # @example
  #    bp = BackendProxy.new(type: :opennebula, options: {}, logger: Rails.logger)
  #    bp.compute.create(instance)
  #    bp.storage.identifiers
  #
  # @param args [Hash] constructor arguments
  # @option args [Symbol] :type type of the backend, see `backend_types`
  # @option args [Hash] :options backend-specific options
  # @option args [Logger] :logger logger instance
  # @option args [Occi::Core::Model] :server_model instance of the server model (OCCI)
  # @option args [Hash] :credentials user credentials for the underlying CMF
  def initialize(args = {})
    @type = args.fetch(:type)
    @options = args.fetch(:options).symbolize_keys
    @logger = args.fetch(:logger)
    @server_model = args.fetch(:server_model, nil)
    @credentials = args.fetch(:credentials)

    flush!
  end

  # Flushes (or initializes) internal backend fragment cache.
  def flush!
    @_cache = {}
  end

  # Checks type of backend used for this instance.
  #
  # @example
  #    bp.is? :opennebula  # => true
  #    bp.is? :dummy       # => false
  #
  # @param btype [Symbol] backend type
  # @return [TrueClass] if backend type matches loaded type
  # @return [FalseClass] if backend type does NOT match loaded type
  def is?(btype)
    type == btype
  end

  class << self
    # Returns backend API version required by this proxy class.
    #
    # @return [String] version of the backend API, semantic
    def api_version
      API_VERSION
    end

    # Checks whether this proxy class provides access to the given backend
    # type.
    #
    # @example
    #    BackendProxy.can_be? :weird  #=> false
    #    BackendProxy.can_be? :dummy  #=> true
    #
    # @param btype [Symbol] backend type
    # @return [TrueClass] if such backend type is available
    # @return [FalseClass] if such backend type is NOT available
    def can_be?(btype)
      backend_types.keys.include?(btype)
    end

    # Checks whether this proxy class provides access to the given backend subtype/fragment.
    #
    # @example
    #    BackendProxy.has? :compute #=> true
    #    BackendProxy.has? :meh     #=> false
    #
    # @param bsubtype [Symbol] backend subtype
    # @return [TrueClass] if backend subtype is available
    # @return [FalseClass] if backend subtype is NOT available
    def has?(bsubtype)
      backend_subtypes.include?(bsubtype)
    end

    # Checks whether this proxy class provides access to an Entity-like backend
    # subtype/fragment.
    #
    # @example
    #    BackendProxy.entitylike? :compute        #=> true
    #    BackendProxy.entitylike? :model_extender #=> false
    #
    # @param bsubtype [Symbol] backend subtype
    # @return [TrueClass] if backend subtype is serving something Entity-like
    # @return [FalseClass] if backend subtype is NOT serving anything Entity-like
    def entitylike?(bsubtype)
      backend_entity_subtypes.include?(bsubtype)
    end

    # @see `entitylike?`
    def resourcelike?(bsubtype)
      backend_resource_subtypes.include?(bsubtype)
    end

    # @see `entitylike?`
    def linklike?(bsubtype)
      backend_link_subtypes.include?(bsubtype)
    end

    # @return [Hash] map of available backend types, `type` => `namespace`
    def backend_types
      BACKEND_TYPES
    end

    # @return [Array] list of available backend subtypes
    def backend_subtypes
      BACKEND_SUBTYPES
    end

    # @return [Array] list of available backend subtypes serving something Resource-like
    def backend_resource_subtypes
      BACKEND_RESOURCE_SUBTYPES
    end

    # @return [Array] list of available backend subtypes serving something Link-like
    def backend_link_subtypes
      BACKEND_LINK_SUBTYPES
    end

    # @return [Array] list of available backend subtypes serving something Entity-like
    def backend_entity_subtypes
      BACKEND_ENTITY_SUBTYPES
    end

    # @return [Array] list of available backend subtypes serving nothing Entity-like
    def backend_non_entity_subtypes
      BACKEND_NON_ENTITY_SUBTYPES
    end
  end

  private

  # :nodoc:
  def method_missing(m, *args, &block)
    m = m.to_sym
    if backend_subtypes.include?(m)
      @_cache[m] ||= initialize_proxy(m)
    else
      super
    end
  end

  # :nodoc:
  def respond_to_missing?(method_name, include_private = false)
    has?(method_name.to_sym) || super
  end

  # :nodoc:
  def initialize_proxy(subtype)
    logger.debug "Creating a proxy for #{subtype} (#{type} backend)"
    bklass = klass_in_namespace(backend_namespace, subtype)
    check_version! api_version, bklass.api_version
    bklass.new default_backend_options.merge(options)
  end

  # :nodoc:
  def default_backend_options
    { logger: logger, backend_proxy: self, credentials: credentials }
  end

  # :nodoc:
  def backend_namespace
    unless backend_types.key?(type)
      raise Errors::BackendLoadError, "Backend type #{type} is not supported"
    end

    backend_types[type]
  end

  # :nodoc:
  def klass_in_namespace(backend_module, subtype)
    unless backend_subtypes.include?(subtype)
      raise Errors::BackendLoadError, "Backend subtype #{subtype} is not supported"
    end

    bsklass = subtype.to_s.classify.to_sym
    unless backend_module.constants.include?(bsklass)
      raise Errors::BackendLoadError, "Backend subtype #{subtype} is not implemented in #{backend_module}"
    end

    backend_module.const_get(bsklass)
  end

  # :nodoc:
  def check_version!(server_version, backend_version)
    s_major, s_minor = server_version.split('.')
    b_major, b_minor = backend_version.split('.')

    unless s_major == b_major
      raise Errors::BackendVersionMismatchError,
            "Backend reports API_VERSION=#{backend_version} and cannot be " \
            "loaded because server's API_VERSION=#{server_version}"
    end

    return if s_minor == b_minor
    logger.warn "Backend reports API_VERSION=#{backend_version} " \
                "and server's API_VERSION=#{server_version}"
  end
end
