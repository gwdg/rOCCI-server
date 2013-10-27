class ApplicationController < ActionController::API
  include ActionController::UrlFor
  include ActionController::Redirecting
  include ActionController::Rendering
  include ActionController::Renderers::All
  include ActionController::ImplicitRender
  include ActionController::MimeResponds

  before_action :authenticate!
  helper_method :warden, :current_user, :request_occi_collection
  respond_to :html, :xml, :json, :text, :occi_xml, :occi_json, :occi_header

  def current_user
    warden.user
  end

  def warden
    request.env['warden']
  end

  def authenticate!
    warden.authenticate!
  end

  def request_occi_collection
    env["rocci_server.request.collection"]
  end
end
