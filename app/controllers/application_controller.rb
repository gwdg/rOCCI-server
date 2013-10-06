class ApplicationController < ActionController::API
  before_action :authenticate!
  helper_method :warden, :current_user

  def current_user
    warden.user
  end

  def warden
    request.env['warden']
  end

  def authenticate!
    warden.authenticate!
  end
end
