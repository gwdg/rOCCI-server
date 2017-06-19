Dir.glob(File.join(File.dirname(__FILE__), 'backends', '*.rb')) { |mod| require mod.chomp('.rb') }

class BackendProxy
  KNOWN_BACKEND_TYPES = {
    dummy: Backends::Dummy,
    opennebula: Backends::OpenNebula,
    aws_ec2: Backends::AwsEc2
  }.freeze
  KNOWN_BACKEND_SUBTYPES = %i[compute network storage storagelink networkinterface].freeze
  API_VERSION = '3.0.0'.freeze

  attr_reader :type, :subtype, :options

  def initialize(args = {})
    @type = args.fetch(:type)
    @subtype = args.fetch(:subtype)
    @options = args.fetch(:options)

    initialize_backend!
  end

  def known_backend_types
    self.class.known_backend_types
  end

  def known_backend_subtypes
    self.class.known_backend_subtypes
  end

  class << self
    def known_backend_types
      KNOWN_BACKEND_TYPES
    end

    def known_backend_subtypes
      KNOWN_BACKEND_SUBTYPES
    end
  end

  private

  def initialize_backend!
    bklass = backend_subtype(backend_type)
    check_version! API_VERSION, bklass::API_VERSION
    @backend = bklass.new(options)
  end

  def backend_type
    known_backend_types[type] || raise("Backend type #{type} is not supported")
  end

  def backend_subtype(backend_module)
    unless known_backend_subtypes.include?(subtype)
      raise "Backend subtype #{subtype} is not supported"
    end

    bsklass = subtype.to_s.capitalize.to_sym
    unless backend_module.constants.include?(bsklass)
      raise "Backend subtype #{subtype} is not implemented in #{backend_module}"
    end

    backend_module.const_get(bsklass)
  end

  def check_version!(api_version, backend_version)
    s_major, s_minor = api_version.split('.')
    b_major, b_minor = backend_version.split('.')

    unless s_major == b_major
      raise Errors::BackendVersionMismatchError,
            "Backend reports API_VERSION=#{backend_version} and cannot be " \
            "loaded because SERVER_API_VERSION=#{api_version}"
    end

    return if s_minor == b_minor
    Rails.logger.warn "Backend reports API_VERSION=#{backend_version} " \
                      "and SERVER_API_VERSION=#{api_version}"
  end
end
