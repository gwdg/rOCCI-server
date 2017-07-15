class ApplicationController < ActionController::API
  include Configurable
  include Authorizable
  include Renderable
  include Errorable

  include BackendAccessible
  include ModelAccessible

  # More convenient access to logging
  delegate :debug?, prefix: true, to: :logger
end
