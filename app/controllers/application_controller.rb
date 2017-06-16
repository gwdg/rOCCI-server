require 'application_responder'
require 'renderable_error'

class ApplicationController < ActionController::API
  ANY_FORMAT = '*/*'.freeze
  NO_FORMAT = ''.freeze
  WRONG_FORMATS = [ANY_FORMAT, NO_FORMAT].freeze
  DEFAULT_FORMAT_SYM = :text
  REDIRECT_HEADER_KEY = 'WWW-Authenticate'.freeze

  # Force SSL, we live in the 21st century after all
  force_ssl

  # Register supported MIME formats
  # @see 'config/initializers/mime_types.rb' for details
  self.responder = ApplicationResponder
  respond_to :uri_list, only: [:locations]
  respond_to :json, :text, :headers

  # Run pre-action checks
  before_action :default_format!
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

  private

  # Checks request format and sets the default 'text/plain' if necessary.
  def default_format!
    return unless WRONG_FORMATS.include?(request.format.to_s)
    logger.debug "Request format in #{WRONG_FORMATS.inspect}, forcing #{DEFAULT_FORMAT_SYM} for compatibility"
    request.format = DEFAULT_FORMAT_SYM
  end

  def authorize_user!
    if request.env['HTTP_X_Auth_Token'].blank?
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
