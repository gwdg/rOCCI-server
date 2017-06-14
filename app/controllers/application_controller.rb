require "application_responder"

class ApplicationController < ActionController::API
  # Register supported MIME formats
  # @see 'config/initializers/mime_types.rb' for details
  self.responder = ApplicationResponder
  respond_to :json, :text, :occi_headers
  respond_to :uri_list, only: [:locations]

  # Set default media type/format if necessary
  before_action :set_default_format

  private

  # Checks request format and sets the default 'text/plain' if necessary.
  def set_default_format
    if request.format.symbol.nil? || request.format.to_s == '*/*'
      logger.debug "Request format empty or */*, forcing 'text/plain'"
      request.format = :text
    end
  end
end
