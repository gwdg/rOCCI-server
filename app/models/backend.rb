# Provides access to the real backend which is loaded
# at runtime. All API calls will be automatically wrapped
# and delegated to the real backend.
class Backend

  # Track accessors to exclude them from debugging logs
  extend TrackAttributes

  # Will need private accessors here
  extend PrivateAttrAccessor

  # Expose API_VERSION
  API_VERSION = '1.0.0'

  # Supported backend types
  BACKEND_TYPES = %w(compute storage network).freeze

  # Default cache expiration
  DEFAULT_CACHE_EXPIRATION = 20.minutes

  # Exposing a few attributes
  attr_reader :options, :server_properties
  private_attr_reader :backend_instances

  # Instantiate backend model.
  #
  # @param delegated_user [Hash] user information
  # @param backend_names [Hash] names keyed by backend type
  # @param options [Hash] backend options keyed by backend type
  # @param server_properties [Hash] global server options
  def initialize(delegated_user = nil, backend_names = {}, options = {}, server_properties = nil)
    @server_properties = server_properties || ROCCI_SERVER_CONFIG.common
    @options = {}
    @backend_instances = {}

    BACKEND_TYPES.each do |backend_type|
      backend_name = backend_names[backend_type] || ROCCI_SERVER_CONFIG.common.backend[backend_type]
      backend_class = self.class.load_backend_class(backend_name, backend_type)
      @options[backend_type] = options[backend_type] || ROCCI_SERVER_CONFIG.backends.send(backend_name.to_sym)

      Rails.logger.debug "[#{self.class}] Instantiating #{backend_class} " \
                         "for delegated_user=#{delegated_user.inspect} " \
                         "with options=#{self.options[backend_type]} and server_properties=#{self.server_properties}"

      @backend_instances[backend_type] = backend_class.new(
        delegated_user, self.options[backend_type],
        self.server_properties, Rails.logger,
        self.class.dalli_instance_factory(
          "#{backend_name}_#{backend_type}",
          self.server_properties.memcaches,
          { expire_after: DEFAULT_CACHE_EXPIRATION },
          "#{self.server_properties.hostname}_#{self.server_properties.port}"
        )
      )
    end

    inject_backends
  end

  # Adds every backend instance to every other backend for reference and internal
  # calls to retrieve resources.
  def inject_backends
    BACKEND_TYPES.each do |backend_type|
      (BACKEND_TYPES - [backend_type]).each do |injected_backend|
        backend_instances[backend_type].add_other_backend(
          injected_backend,
          backend_instances[injected_backend]
        )
      end
    end
  end
  private :inject_backends

  # Performs deep cloning on given Object. Returned
  # instance is completely independent.
  #
  # @param object [Object] instance to be cloned
  # @return [Object] a deep clone
  def deep_clone(object)
    Marshal.load(Marshal.dump(object))
  end
  private :deep_clone

  # Load API fragments
  BACKEND_TYPES.each do |backend_api|
    include BackendApi.const_get(backend_api.camelize)
  end

  # Returns a collection of custom mixins introduced (and specific for)
  # all enabled backends. Only mixins and actions are allowed.
  #
  # @return [Occi::Collection] all registered extensions in a collection
  def get_extensions
    collection = Occi::Collection.new
    BACKEND_TYPES.each { |backend_type| collection.merge! backend_instances[backend_type].get_extensions }
    collection
  end

  class << self
    # Matches the given backend name with the real backend class.
    # Raises an exception if such a backend does not exist.
    #
    # @example
    #    Backend.load_backend_class('dummy', 'compute') #=> Backends::Dummy::Compute
    #
    # @param backend_name [String] name of the chosen backend
    # @param backend_type [String] type of the chosen backend
    # @return [Class] a class of the given backend
    def load_backend_class(backend_name, backend_type)
      backend_name = backend_name.camelize
      backend_type = backend_type.camelize
      Rails.logger.info "[#{self}] Loading Backends::#{backend_name}::#{backend_type}"

      begin
        backend_class = Backends.const_get(backend_name).const_get(backend_type)
      rescue NameError => err
        message = "There is no such valid backend available! " \
                  "[Backends::#{backend_name}::#{backend_type}] #{err.message}"
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
    def check_version(api_version, backend_version)
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
    def dalli_instance_factory(backend_name, endpoints = nil, options = {}, instance_namespace = nil)
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
  end

  # Enable tracing for non-production environments
  # requires TrackAttributes (extend)
  extend MethodLoggerHelper unless Rails.env.production?
end
