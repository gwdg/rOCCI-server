class ApplicationController < ActionController::API
  include ActionController::UrlFor
  include ActionController::Redirecting
  include ActionController::Rendering
  include ActionController::Renderers::All
  include ActionController::ImplicitRender
  include ActionController::MimeResponds

  around_filter :global_request_logging unless Rails.env.production?
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

  private

  def global_request_logging
    http_request_header_keys = request.headers.env.keys.select { |header_name| header_name.match("^HTTP.*") }
    http_request_headers = request.headers.select { |header_name, header_value| http_request_header_keys.index(header_name) }
    logger.debug "Processing with headers #{http_request_headers.inspect} and params #{params.inspect}"
    logger.debug "Processing with body #{request.body.string.inspect}"
    logger.debug "Processing with parsed OCCI message #{request_occi_collection.inspect}"
    begin
      yield
    ensure
      logger.debug "Responding with #{response.status.inspect} => #{response.body.inspect}"
    end
  end
end
