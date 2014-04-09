# Base class for all rOCCI-server's controllers. Implements
# parsing and authentication callbacks, exposes user information,
# declares supported media formats and handles raised errors.
class ApplicationController < ActionController::API
  # Include some stuff present in the full ActionController
  # include ActionController::UrlFor
  # include ActionController::Redirecting
  include ActionController::Rendering
  include ActionController::Renderers::All
  include ActionController::ImplicitRender
  include ActionController::MimeResponds

  # Handle known exceptions
  rescue_from ::Errors::UnsupportedMediaTypeError, with: :handle_parser_type_err
  rescue_from ::Occi::Errors::ParserInputError, with: :handle_parser_input_err
  rescue_from ::Backends::Errors::MethodNotImplementedError, with: :handle_not_impl_err
  rescue_from ::Errors::ArgumentTypeMismatchError, with: :handle_wrong_args_err
  rescue_from ::Errors::ArgumentError, with: :handle_wrong_args_err
  rescue_from ::Backends::Errors::StubError, with: :handle_not_impl_err
  rescue_from ::Backends::Errors::IdentifierConflictError, with: :handle_invalid_resource_err
  rescue_from ::Backends::Errors::IdentifierNotValidError, with: :handle_resource_not_found_err
  rescue_from ::Backends::Errors::ResourceNotFoundError, with: :handle_resource_not_found_err
  rescue_from ::Backends::Errors::ResourceNotValidError, with: :handle_invalid_resource_err
  rescue_from ::Occi::Errors::KindNotDefinedError, with: :handle_parser_input_err
  rescue_from ::Occi::Errors::CategoryNotDefinedError, with: :handle_parser_input_err
  rescue_from ::Occi::Errors::AttributeNotDefinedError, with: :handle_parser_input_err
  rescue_from ::Occi::Errors::AttributeTypeError, with: :handle_parser_input_err
  rescue_from ::Occi::Errors::AttributeMissingError, with: :handle_wrong_args_err
  rescue_from ::Backends::Errors::ResourceRetrievalError, with: :handle_resource_not_found_err
  rescue_from ::Backends::Errors::ResourceActionError, with: :handle_internal_backend_err
  rescue_from ::Backends::Errors::ResourceCreationError, with: :handle_wrong_args_err
  rescue_from ::Backends::Errors::ServiceUnavailableError, with: :handle_internal_backend_err
  rescue_from ::Backends::Errors::ResourceStateError, with: :handle_invalid_resource_err
  rescue_from ::Backends::Errors::AuthenticationError, with: :handle_auth_err
  rescue_from ::Backends::Errors::UserNotAuthorizedError, with: :handle_authz_err
  rescue_from ::Backends::Errors::ActionNotImplementedError, with: :handle_not_impl_err

  include Mixins::ErrorHandling

  # Wrap actions in a request logger, only in non-production envs
  around_filter :global_request_logging if ROCCI_SERVER_CONFIG.common.log_requests_in_debug

  # Force authentication, if not already authenticated
  before_action :authenticate!

  # Expose chosen methods in views
  helper_method :warden, :current_user, :request_occi_collection

  # Register supported MIME formats
  # @see 'config/initializers/mime_types.rb' for details
  respond_to :json, :occi_json #, :xml, :occi_xml
  respond_to :occi_header, :text, except: [:index]
  respond_to :uri_list, only: [:index]
  respond_to :html, only: [:index, :show]

  # Provides access to a structure containing authentication data
  # intended for delegation to the backend.
  #
  # @return [Hashie::Mash] a hash containing authentication data
  def current_user
    if Rails.env.test?
      # turn off caching for tests
      @current_user = warden.user
    else
      @current_user ||= warden.user
    end
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
  # @param expected_entity_type [Object] parameter passed as 'entity_type' to Occi::Parser.parse
  # @return [Occi::Collection] collection containig parsed OCCI request
  def request_occi_collection(expected_entity_type = nil)
    if Rails.env.test?
      # turn off caching for tests
      @request_collection = parse_request(expected_entity_type)
    else
      @request_collection ||= parse_request(expected_entity_type)
    end
  end

  protected

  # Provides access to and caching for the active backend instance.
  #
  # @return [Backend] instance of the backend
  def backend_instance
    if Rails.env.test?
      # turn off caching for tests
      @backend_instance = Backend.new(current_user)
    else
      @backend_instance ||= Backend.new(current_user)
    end
  end

  # Provides access to a lazy parser object
  #
  # @param expected_entity_type [Object] parameter passed as 'entity_type' to Occi::Parser.parse
  # @return [Occi::Collection] collection of parsed OCCI objects
  def parse_request(expected_entity_type = nil)
    request_collection = request.env['rocci_server.request.parser'].parse_occi_messages(expected_entity_type)
    request_collection ||= Occi::Collection.new

    request_collection.model = OcciModel.get(backend_instance)
    request_collection.check(check_categories = true, set_default_attrs = true)

    request_collection
  end

  # Provides access to user-configured server URL
  #
  # @return [String] FQDN of the server, including the port number
  def server_url
    "#{ROCCI_SERVER_CONFIG.common.protocol || 'http'}://" \
    "#{ROCCI_SERVER_CONFIG.common.hostname || 'localhost'}:" \
    "#{ROCCI_SERVER_CONFIG.common.port.to_s || '3000'}"
  end

  # Runs basic checks matching ActionInstance content with action name declared
  # in the 'query_string'
  def check_ai!(ai, query_string)
    action_param = action_from_query_string(query_string)
    fail ::Errors::ArgumentError, 'Provided action does not have a term!' unless ai && ai.action && ai.action.term
    fail ::Errors::ArgumentTypeMismatchError, 'Action terms in params and body do not match!' unless ai.action.term == action_param
  end

  private

  # Action wrapper providing logging capabilities, mostly for debugging purposes.
  def global_request_logging
    http_request_header_keys = request.headers.env.keys.select { |header_name| header_name.match('^HTTP.*') }
    http_request_headers = request.headers.select { |header_name, header_value| http_request_header_keys.index(header_name) }

    logger.debug "[ApplicationController] Processing with params #{params.inspect}"
    if request.body.respond_to?(:read) && request.body.respond_to?(:rewind)
      request.body.rewind
      logger.debug "[ApplicationController] Processing with body #{request.body.read.inspect}"
    end

    # Run Warden if not already done, to avoid incomplete log entries after authN fail
    authenticate!

    begin
      yield
    ensure
      logger.debug "[ApplicationController] Responding with headers #{response.headers.inspect}"
      logger.debug "[ApplicationController] Responding with body #{response.body.inspect}"
    end
  end

  # Extracts action term from a 'query_string'
  #
  # @example
  #    action_from_query_string('action=stop') # => 'stop'
  #
  # @param query_string [String] query string
  # @return [String] action term
  def action_from_query_string(query_string)
    return '' if query_string.blank?

    matched = /^action=(?<act>\S+)$/.match(query_string)
    matched[:act]
  end
end
