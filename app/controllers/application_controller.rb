class ApplicationController < ActionController::API

  # Include some stuff present in the full ActionController
  include ActionController::UrlFor
  include ActionController::Redirecting
  include ActionController::Rendering
  include ActionController::Renderers::All
  include ActionController::ImplicitRender
  include ActionController::MimeResponds

  # Wrap actions in a request logger, only in non-production envs
  around_filter :global_request_logging unless Rails.env.production?

  # Force authentication, if not already authenticated
  before_action :authenticate!

  # Expose chosen methods in views
  helper_method :warden, :current_user, :request_occi_collection

  # Register supported MIME formats
  # @see 'config/initializers/mime_types.rb' for details
  respond_to :html, :xml, :json, :text, :occi_xml, :occi_json, :occi_header, :uri_list

  # Provides access to a structure containing authentication data
  # intended for delegation to the backend.
  #
  # @return [Hashie::Mash] a hash containing authentication data
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
    logger.debug "[ApplicationController] Processing with params #{params.inspect}"
    logger.debug "[ApplicationController] Processing with body #{request.body.read.inspect}" if request.body.respond_to?(:read)
    logger.debug "[ApplicationController] Processing with parsed OCCI message #{request_occi_collection.inspect}"
    begin
      yield
    ensure
      logger.debug "[ApplicationController] Responding with body #{response.body.inspect}"
    end
  end
end
