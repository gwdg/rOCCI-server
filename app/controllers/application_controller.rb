require 'application_responder'
require 'renderable_error'

class ApplicationController < ActionController::API
  ANY_FORMAT = '*/*'.freeze
  NO_FORMAT = ''.freeze
  WRONG_FORMATS = [ANY_FORMAT, NO_FORMAT].freeze
  DEFAULT_FORMAT_SYM = :text

  # Force SSL, we live in the 21st century after all
  force_ssl

  # Register supported MIME formats
  # @see 'config/initializers/mime_types.rb' for details
  self.responder = ApplicationResponder
  respond_to :uri_list, only: [:locations]
  respond_to :json, :text, :headers

  # Run pre-action checks
  before_action :set_default_format
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

  private

  # Checks request format and sets the default 'text/plain' if necessary.
  def set_default_format
    return unless WRONG_FORMATS.include?(request.format.to_s)
    logger.debug "Request format in #{WRONG_FORMATS.inspect}, forcing #{DEFAULT_FORMAT_SYM} for compatibility"
    request.format = DEFAULT_FORMAT_SYM
  end
end
