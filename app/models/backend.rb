class Backend

  include Singleton

  cattr_accessor :backend_class, :options, :server_properties

  def initialize
    raise Errors::BackendClassNotSetError, 'No backend class has been defined!' unless Backend.backend_class
    raise Errors::BackendClassNotSetError, 'No backend options have been defined!' unless Backend.options
    raise Errors::BackendClassNotSetError, 'No backend server properties have been defined!' unless Backend.server_properties

    @backend_instance = Backend.backend_class.new(
      Backend.options, Backend.server_properties
    )

    @backend_instance.extend(Backends::Helpers::MethodMissingHelper) unless @backend_instance.respond_to? :method_missing
  end

  def method_missing(m, *args, &block)
    raise Errors::MethodNotImplementedError, "Method is not implemented in the backend model! [#{m}]"
  end

  include BackendApi::Model
  include BackendApi::Compute
  include BackendApi::Network
  include BackendApi::Storage
  include BackendApi::OsTpl
  include BackendApi::ResourceTpl

end