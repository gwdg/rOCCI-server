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
end
