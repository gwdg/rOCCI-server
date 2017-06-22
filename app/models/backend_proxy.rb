module Backends; end
Dir.glob(File.join(File.dirname(__FILE__), 'backends', '*.rb')) { |mod| require mod.chomp('.rb') }

class BackendProxy
  BACKEND_TYPES = {
    dummy: Backends::Dummy,
    opennebula: Backends::OpenNebula,
    aws_ec2: Backends::AwsEc2
  }.freeze
  BACKEND_SUBTYPES = %i[
    compute network storage securitygroup ipreservation
    storagelink networkinterface securitygrouplink
    model_extender
  ].freeze
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

  def known_backend_types
    BACKEND_TYPES
  end

  def known_backend_subtypes
    BACKEND_SUBTYPES
  end

  class << self
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
    known_backend_subtypes.include?(method_name.to_sym) || super
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
