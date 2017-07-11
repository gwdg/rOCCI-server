class ApplicationController < ActionController::API
  include Configurable
  include Authorizable
  include Renderable
  include Errorable

  include BackendAccessible
  include ModelAccessible

  # Just in case
  force_ssl

  # More convenient access to logging
  delegate :debug?, prefix: true, to: :logger

  # Returns default backend instance for the given controller. This method should be overriden in every
  # controller (sub)class.
  #
  # @return [Entitylike, Extenderlike] subtype instance
  def default_backend_proxy
    backend_proxy_for 'model_extender'
  end
end
