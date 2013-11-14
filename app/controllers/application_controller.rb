class ApplicationController < ActionController::API

  # Include some stuff present in the full ActionController
  #include ActionController::UrlFor
  #include ActionController::Redirecting
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
  respond_to :xml, :json, :occi_xml, :occi_json
  respond_to :occi_header, :text, :except => [ :index ]
  respond_to :uri_list, :only => [ :index ]
  respond_to :html, :only => [ :index, :show ]

  # Provides access to a structure containing authentication data
  # intended for delegation to the backend.
  #
  # @return [Hashie::Mash] a hash containing authentication data
  def current_user
    warden.user
  end

  # Provides access to a lazy authN object from Warden.
  #
  # @return [Warden::Manager]
  def warden
    request.env['warden']
  end

  # Performs authentication with Warden. Warden will raise
  # an exception and redirect to UnauthorizedController.
  def authenticate!
    warden.authenticate!
  end

  # Provides access to a request collection prepared
  # by the RequestParser.
  #
  # @return [Occi::Collection] collection containig parsed OCCI request
  def request_occi_collection
    env["rocci_server.request.collection"] || Occi::Collection.new
  end

  private

  # Action wrapper providing logging capabilities, mostly for debugging purposes.
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
