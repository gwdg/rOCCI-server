# Provides access to the real backend which is loaded
# at runtime. All API calls will be automatically wrapped
# and delegated to the real backend.
class Backend
  # Expose API_VERSION
  API_VERSION = '0.0.1'

  # Exposing a few attributes
  attr_reader :backend_name, :backend_class, :options, :server_properties

  def initialize(delegated_user = nil, backend_name = nil, options = nil, server_properties = nil)
    @backend_name = backend_name || ROCCI_SERVER_CONFIG.common.backend

    @backend_class = Backend.load_backend_class(@backend_name)
    @options = options || ROCCI_SERVER_CONFIG.backends.send(@backend_name.to_sym)
    @server_properties = server_properties || ROCCI_SERVER_CONFIG.common

    Rails.logger.debug "[#{self.class}] Instantiating #{@backend_class} " <<
                       "for delegated_user=#{delegated_user.inspect} " <<
                       "with options=#{@options} and server_properties=#{@server_properties}"

    @backend_instance = @backend_class.new(
      delegated_user, @options,
      @server_properties, Rails.logger,
      Backend.dalli_instance_factory(
        @backend_name,
        @server_properties.memcaches,
        { expire_after: 20.minutes },
        "#{@server_properties.hostname}_#{@server_properties.port}"
      )
    )

    @backend_instance.extend(Backends::Helpers::MethodMissingHelper) unless @backend_instance.respond_to? :method_missing
  end

  # Raises a custom error when it encounters a method which
  # does not exist.
  #
  # @param m [Symbol] method name
  # @param args [Array] an array of method arguments
  # @param block [Proc] a block passed to the method
  def method_missing(m, *args, &block)
    fail Errors::MethodNotImplementedError, "Method is not implemented in the backend model! [#{m}]"
  end

  # Performs deep cloning on given Object. Returned
  # instance is completely independent.
  #
  # @param object [Object] instance to be cloned
  # @return [Object] a deep clone
  def deep_clone(object)
    # TODO: too expensive?
    Marshal.load(Marshal.dump(object))
  end

  # Matches the given backend name with the real backend class.
  # Raises an exception if such a backend does not exist.
  #
  # @example
  #    Backend.load_backend_class('dummy') #=> Backends::Dummy
  #
  # @param backend_name [String] name of the chosen backend
  # @return [Class] a class of the given backend
  def self.load_backend_class(backend_name)
    backend_name = "#{backend_name.camelize}Backend"
    Rails.logger.info "[#{self}] Loading Backends::#{backend_name}"

    begin
      backend_class = Backends.const_get(backend_name)
    rescue NameError => err
      message = "There is no such valid backend available! " \
                "[Backends::#{backend_name}] #{err.message}"
      Rails.logger.error "[#{self}] #{message}"
      raise ArgumentError, message
    end

    backend_class
  end

  # Checks backend version against the declared API version.
  #
  # @example
  #    Backend.check_version('1.0', '2.5')
  #
  # @param api_version [String] current API version of the server
  # @param backend_version [String] API version of the backend
  # @return [true, false] result of the check or raised exception
  def self.check_version(api_version, backend_version)
    s_major, s_minor, s_fix = api_version.split('.')
    b_major, b_minor, b_fix = backend_version.split('.')

    unless s_major == b_major
      message = "Backend reports API_VERSION=#{backend_version} and cannot be loaded because SERVER_API_VERSION=#{api_version}"
      Rails.logger.error "[#{self}] #{message}"
      fail Errors::BackendApiVersionMismatchError, message
    end

    unless s_minor == b_minor
      Rails.logger.warn "[#{self}] Backend reports API_VERSION=#{backend_version} and SERVER_API_VERSION=#{api_version}"
    end

    true
  end

  # Constructs a backend-specific Dalli instance for caching purposes.
  #
  # @example
  #    Backend.dalli_instance_factory("dummy", "localhost:11211", { :expire_after => 20.minutes })
  #    # => #<Dalli::Client>
  #
  # @param backend_name [String] name of the target backend, for namespacing
  # @param endpoints [String] memcache endpoints, address:port
  # @param options [Hash] options for Dalli::Client
  # @param instance_namespace [String] string used to differentiate between different instance namespaces
  # @return [Dalli::Client] constructed Dalli::Client instance
  def self.dalli_instance_factory(backend_name, endpoints = nil, options = {}, instance_namespace = nil)
    fail ArgumentError, 'Dalli instance cannot be constructed without a backend_name!' if backend_name.blank?
    endpoints ||= 'localhost:11211'

    defaults = { compress: true }
    defaults.merge! options

    if instance_namespace.blank?
      defaults[:namespace] = "ROCCIServer.backend_cache.#{backend_name}"
    else
      defaults[:namespace] = "ROCCIServer_#{instance_namespace}.backend_cache.#{backend_name}"
    end
    Dalli::Client.new(endpoints, defaults)
  end

  include BackendApi::Compute
  include BackendApi::Network
  include BackendApi::Storage
  include BackendApi::OsTpl
  include BackendApi::ResourceTpl

  include MethodLoggerHelper unless Rails.env.production?
end
