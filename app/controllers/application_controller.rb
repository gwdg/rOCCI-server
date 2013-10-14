class ApplicationController < ActionController::API
  include ActionController::UrlFor
  include ActionController::Redirecting
  include ActionController::Rendering
  include ActionController::Renderers::All
  include ActionController::MimeResponds

  before_action :authenticate!
  helper_method :warden, :current_user
  respond_to :html, :xml, :json, :text, :occi, :occi_json, :occi_xml

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
