require 'application_responder'
require 'renderable_error'

class ApplicationController < ActionController::API
  URI_FORMATS = %i[uri_list]
  FULL_FORMATS = %i[json text headers]
  ALL_FORMATS = [URI_FORMATS, FULL_FORMATS].flatten.freeze
  UBIQUITOUS_FORMATS = %w[*/*].freeze
  DEFAULT_FORMAT_SYM = FULL_FORMATS.first

  TOKEN_HEADER_KEY = 'HTTP_X_AUTH_TOKEN'.freeze
  REDIRECT_HEADER_KEY = 'WWW-Authenticate'.freeze
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
    @current_user || 'unauthorized'
  end

  def server_model
    @model || bootstrap_server_model!
  end

  def bootstrap_server_model!
    @model = Occi::InfrastructureExt::Model.new
    MODEL_FLAVORS.each { |flv| @model.send "load_#{flv}!" }
    @model.valid!

    @model
  end

  private

  def validate_format!
    if UBIQUITOUS_FORMATS.include?(request.format.to_s)
      logger.debug "Changing ubiquitous format #{request.format.to_s.inspect} to #{DEFAULT_FORMAT_SYM.inspect}"
      request.format = DEFAULT_FORMAT_SYM
    end

    return if ALL_FORMATS.include?(request.format.symbol)
    render_error 406, 'Requested media format is not acceptable'
  end

  def authorize_user!
    if request.env[TOKEN_HEADER_KEY].blank?
      auth_redirect_header!
      render_error 401, 'Not Authorized'
    else
      decrypt_user_token!
    end
  end

  def decrypt_user_token!
    # TODO: decrypt token and store username
    # TODO: read secret from configuration
    @current_user = nil
    @decrypted_token = nil
  end

  def auth_redirect_header!
    response.headers[REDIRECT_HEADER_KEY] = "Keystone uri='#{Rails.configuration.rocci_server['keystone_uri']}'"
  end
end
