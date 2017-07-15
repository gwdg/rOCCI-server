module Backends; end
Dir.glob(File.join(File.dirname(__FILE__), 'backends', '*.rb')) { |mod| require mod.chomp('.rb') }

class BackendProxy
  #
  BACKEND_TYPES = {
    dummy: Backends::Dummy,
    opennebula: Backends::OpenNebula,
    aws_ec2: Backends::AwsEc2
  }.freeze

  #
  BACKEND_ENTITY_SUBTYPES = %i[
    compute network storage securitygroup ipreservation
    storagelink networkinterface securitygrouplink
  ].freeze
  BACKEND_NON_ENTITY_SUBTYPES = %i[model_extender].freeze
  BACKEND_SUBTYPES = [
    BACKEND_ENTITY_SUBTYPES,
    BACKEND_NON_ENTITY_SUBTYPES
  ].flatten.freeze

  #
  API_VERSION = '3.0.0'.freeze

  attr_accessor :type, :options, :logger
  delegate :api_version, to: :class

  def initialize(args = {})
    @type = args.fetch(:type)
    @options = args.fetch(:options)
    @logger = args.fetch(:logger)

    flush!
  end

  def flush!
    @_cache = {}
  end

  #
  # @param btype [Symbol] backend type
  # @return [TrueClass] if such backend type is available
  # @return [FalseClass] if such backend type is NOT available
  def can_be?(btype)
    known_backend_types.keys.include?(btype)
  end

  #
  # @param btype [Symbol] backend type
  # @return [TrueClass] if backend type matches loaded type
  # @return [FalseClass] if backend type does NOT match loaded type
  def is?(btype)
    type == btype
  end

  #
  # @param bsubtype [Symbol] backend subtype
  # @return [TrueClass] if backend subtype is available
  # @return [FalseClass] if backend subtype is NOT available
  def has?(bsubtype)
    known_backend_subtypes.include?(bsubtype)
  end

  #
  # @param bsubtype [Symbol] backend subtype
  # @return [TrueClass] if backend subtype is serving something Entity-like
  # @return [FalseClass] if backend subtype is NOT serving anything Entity-like
  def entitylike?(bsubtype)
    known_backend_entity_subtypes.include?(bsubtype)
  end

  #
  # @return [Hash] map of available backend types, `type` => `namespace`
  def known_backend_types
    BACKEND_TYPES
  end

  #
  # @return [Array] list of available backend subtypes
  def known_backend_subtypes
    BACKEND_SUBTYPES
  end

  #
  # @return [Array] list of available backend subtypes serving something Entity-like
  def known_backend_entity_subtypes
    BACKEND_ENTITY_SUBTYPES
  end

  #
  # @return [Array] list of available backend subtypes serving nothing Entity-like
  def known_backend_non_entity_subtypes
    BACKEND_NON_ENTITY_SUBTYPES
  end

  class << self
    #
    # @return [String] version of the backend API, semantic
    def api_version
      API_VERSION
    end
  end

  private

  def method_missing(m, *args, &block)
    m = m.to_sym
    if known_backend_subtypes.include?(m)
      logger.debug "Creating a proxy for #{m} (#{type} backend)"
      @_cache[m] ||= initialize_proxy(m)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    has?(method_name.to_sym) || super
  end

  def initialize_proxy(subtype)
    bklass = klass_in_namespace(backend_namespace, subtype)
    check_version! api_version, bklass.api_version
    bklass.new default_backend_options.merge(options)
  end

  def default_backend_options
    { logger: logger, backend_proxy: self }
  end

  def backend_namespace
    unless known_backend_types.key?(type)
      raise Errors::BackendLoadError, "Backend type #{type} is not supported"
    end

    known_backend_types[type]
  end

  def klass_in_namespace(backend_module, subtype)
    unless known_backend_subtypes.include?(subtype)
      raise Errors::BackendLoadError, "Backend subtype #{subtype} is not supported"
    end

    bsklass = subtype.to_s.classify.to_sym
    unless backend_module.constants.include?(bsklass)
      raise Errors::BackendLoadError, "Backend subtype #{subtype} is not implemented in #{backend_module}"
    end

    backend_module.const_get(bsklass)
  end

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
