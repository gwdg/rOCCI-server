# Provides access to the real backend which is loaded
# at runtime. This class is a Singleton.
#
# @example
#    Backend.instance #=> #<Backend>
#
class Backend

  include Singleton

  # Expose API_VERSION
  API_VERSION = "0.0.1"

  # Exposing a few attributes
  attr_reader :backend_name, :backend_class, :options, :server_properties

  def initialize
    @backend_name = ROCCI_SERVER_CONFIG.common.backend

    @backend_class = Backend.load_backend_class(@backend_name)
    @options = ROCCI_SERVER_CONFIG.backends.send(@backend_name.to_sym)
    @server_properties = ROCCI_SERVER_CONFIG.common

    @backend_instance = @backend_class.new(
      @options, @server_properties, Rails.logger
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
    raise Errors::MethodNotImplementedError, "Method is not implemented in the backend model! [#{m}]"
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
    backend_name = "#{backend_name.camelize}"
    Rails.logger.info "[Backend] Loading Backends::#{backend_name}."

    begin
      backend_class = Backends.const_get("#{backend_name}")
    rescue NameError => err
      message = "There is no such backend available! [Backends::#{backend_name}]"
      Rails.logger.error "[Backend] #{message}"
      raise ArgumentError, message
    end

    backend_class
  end

  def self.check_version(backend_name)
    s_major, s_minor, s_fix = Backend::API_VERSION.split('.')

    b_class = Backend.load_backend_class(ROCCI_SERVER_CONFIG.common.backend)
    unless b_class.const_defined?(:API_VERSION)
      message = "#{b_class} does not expose API_VERSION and cannot be loaded"
      Rails.logger.error "[Backend] #{message}"
      raise ArgumentError, message
    end

    b_major, b_minor, b_fix = b_class::API_VERSION.split('.')
    unless s_major == b_major
      message = "#{b_class} reports API_VERSION=#{b_class::API_VERSION} and cannot be loaded => SERVER_API_VERSION=#{Backend::API_VERSION}"
      Rails.logger.error "[Backend] #{message}"
      raise Errors::BackendApiVersionMismatchError, message
    end

    unless s_minor == b_minor
      Rails.logger.warn "[Backend] #{b_class} reports API_VERSION=#{b_class::API_VERSION} and SERVER_API_VERSION=#{Backend::API_VERSION}"
    end
  end

  include BackendApi::Compute
  include BackendApi::Network
  include BackendApi::Storage
  include BackendApi::OsTpl
  include BackendApi::ResourceTpl

end