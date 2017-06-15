require "application_responder"

class ApplicationController < ActionController::API
  ANY_FORMAT = '*/*'.freeze
  NO_FORMAT = ''.freeze
  WRONG_FORMATS = [ANY_FORMAT, NO_FORMAT].freeze
  DEFAULT_FORMAT_SYM = :text

  # Register supported MIME formats
  # @see 'config/initializers/mime_types.rb' for details
  self.responder = ApplicationResponder
  respond_to :uri_list, only: [:locations]
  respond_to :json, :text, :headers

  # Set default media type/format if necessary
  before_action :set_default_format

  private

  # Checks request format and sets the default 'text/plain' if necessary.
  def set_default_format
    return unless WRONG_FORMATS.include?(request.format.to_s)
    logger.debug "Request format in #{WRONG_FORMATS.inspect}, forcing #{DEFAULT_FORMAT_SYM} for compatibility"
    request.format = DEFAULT_FORMAT_SYM
  end
end
