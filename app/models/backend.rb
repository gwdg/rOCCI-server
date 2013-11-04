class Backend

  include Singleton

  cattr_accessor :backend_class, :options, :server_properties

  def initialize
    backend_name = ROCCI_SERVER_CONFIG.common.backend

    Backend.backend_class = Backend.load_backend_class(backend_name)
    Backend.options = ROCCI_SERVER_CONFIG.backends.send(backend_name.to_sym)
    Backend.server_properties = ROCCI_SERVER_CONFIG.common

    @backend_instance = Backend.backend_class.new(
      Backend.options, Backend.server_properties
    )

    @backend_instance.extend(Backends::Helpers::MethodMissingHelper) unless @backend_instance.respond_to? :method_missing
  end

  def method_missing(m, *args, &block)
    raise Errors::MethodNotImplementedError, "Method is not implemented in the backend model! [#{m}]"
  end

  def self.load_backend_class(backend_name)
    backend_name = "#{backend_name.classify}"
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

  include BackendApi::Model
  include BackendApi::Compute
  include BackendApi::Network
  include BackendApi::Storage
  include BackendApi::OsTpl
  include BackendApi::ResourceTpl

end