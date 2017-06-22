class ApplicationController < ActionController::API
  class << self
    def app_config
      Rails.configuration.rocci_server
    end
  end

  URI_FORMATS = %i[uri_list].freeze
  FULL_FORMATS = %i[json text headers].freeze
  ALL_FORMATS = [URI_FORMATS, FULL_FORMATS].flatten.freeze
  UBIQUITOUS_FORMATS = %w[*/*].freeze
  DEFAULT_FORMAT_SYM = FULL_FORMATS.first

  REDIRECT_HEADER_KEY = 'WWW-Authenticate'.freeze
  REDIRECT_HEADER_URI = "Keystone uri='#{app_config['keystone_uri']}'".freeze

  MODEL_FLAVORS = %w[core infrastructure infrastructure_ext].freeze

  # Force SSL, we live in the 21st century after all
  force_ssl

  # Register supported MIME formats
  # @see 'config/initializers/mime_types.rb' for details
  self.responder = ApplicationResponder
  respond_to(*URI_FORMATS, only: %i[locations])
  respond_to(*FULL_FORMATS)

  # Run pre-action checks
  before_action :validate_format!
  before_action :authorize_user!

  # More convenient access to configuration and logging
  delegate :app_config, to: :class
  delegate :debug?, prefix: true, to: :logger

  # Error handling
  rescue_from Errors::Backend::AuthorizationError, with: :handle_authorization_error

  protected

  def render_error(code, message)
    respond_with RenderableError.new(code, message), status: code
  end

  def current_user
    authorize_user! if authorization_pending?
    @_current_user
  end

  def current_token
    authorize_user! if authorization_pending?
    @_current_token
  end

  def authorization_pending?
    @_user_authorized.nil?
  end

  def server_model
    return @_server_model if @_server_model

    bootstrap_server_model!
    extend_server_model!
    @_server_model
  end

  def bootstrap_server_model!
    logger.debug "Bootstrapping server model with #{MODEL_FLAVORS}"
    @_server_model = Occi::InfrastructureExt::Model.new
    MODEL_FLAVORS.each { |flv| @_server_model.send "load_#{flv}!" }
    @_server_model
  end

  def extend_server_model!
    logger.debug 'Extending server model with backend mixins'
    default_backend_proxy.populate! @_server_model
  end

  def backend_proxy
    return @_backend_proxy if @_backend_proxy

    backend_type = app_config.fetch('backend')
    logger.debug "Starting backend proxy for #{backend_type}"
    @_backend_proxy = BackendProxy.new(
      type: backend_type.to_sym,
      options: app_config.fetch(backend_type, {}),
      logger: logger
    )
  end

  def default_backend_proxy
    backend_proxy.model_extender
  end

  private

  def validate_format!
    if UBIQUITOUS_FORMATS.include?(request.format.to_s)
      logger.debug "Changing ubiquitous format #{request.format} to #{DEFAULT_FORMAT_SYM}"
      request.format = DEFAULT_FORMAT_SYM
    end

    return if ALL_FORMATS.include?(request.format.symbol)
    render_error 406, 'Requested media format is not acceptable'
  end

  def authorize_user!
    logger.debug "User authorization data #{request_user.inspect}:#{request_token.inspect}" if logger_debug?

    if request_authorized?
      @_user_authorized = true
      @_current_token = request_token
      @_current_user = request_user
    else
      @_user_authorized = false
      @_current_token = nil
      @_current_user = 'unauthorized'
    end
  end

  def request_token
    request.env['rocci_server.request.tokenator.token']
  end

  def request_user
    request.env['rocci_server.request.tokenator.user']
  end

  def request_authorized?
    request.env['rocci_server.request.tokenator.authorized']
  end

  def handle_authorization_error
    response.headers[REDIRECT_HEADER_KEY] = REDIRECT_HEADER_URI
    render_error 401, 'Not Authorized'
  end
end
