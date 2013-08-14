require 'dm-rails/middleware/identity_map'

class ApplicationController < ActionController::Base
  # Integrate DM
  use Rails::DataMapper::Middleware::IdentityMap

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
end
