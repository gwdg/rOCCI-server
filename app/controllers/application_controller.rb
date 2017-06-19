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
  before_action :validate_url_param

  # More convenient access to configuration
  delegate :app_config, to: :class

  # Error handling
  rescue_from Errors::BackendAuthorizationError, with: :handle_authorization_error

  protected

  def validate_url_param
    return if url_param_key && acceptable_url_params.include?(params[url_param_key])
    render_error 400, 'Requested entity sub-type is not available'
  end

  def url_param_key
    nil # implement this in Resource/Link/Mixin controllers
  end

  def acceptable_url_params
    [] # implement this in Resource/Link/Mixin controllers
  end

  def render_error(code, message)
    respond_with RenderableError.new(code, message), status: code
  end

  def current_user
    authorize_user! if @_user_authorized.nil?
    @_current_user
  end

  def current_token
    authorize_user! if @_user_authorized.nil?
    @_current_token
  end

  def server_model
    return @_server_model if @_server_model

    bootstrap_server_model!
    extend_server_model!
    @_server_model
  end

  def bootstrap_server_model!
    @_server_model = Occi::InfrastructureExt::Model.new
    MODEL_FLAVORS.each { |flv| @_server_model.send "load_#{flv}!" }
    @_server_model
  end

  def extend_server_model!
    @_server_model # TODO: pass this to the active backend and let it add new mixins
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
    if request.env['rocci_server.request.tokenator.authorized']
      @_user_authorized = true
      @_current_user = request.env['rocci_server.request.tokenator.user']
      @_current_token = request.env['rocci_server.request.tokenator.token']
    else
      @_user_authorized = false
      @_current_user = 'unauthorized'
      @_current_token = nil
    end
  end

  def handle_authorization_error
    response.headers[REDIRECT_HEADER_KEY] = REDIRECT_HEADER_URI
    render_error 401, 'Not Authorized'
  end
end
