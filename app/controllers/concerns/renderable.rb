module Renderable
  extend ActiveSupport::Concern

  # Format constants
  URI_FORMATS = %i[uri_list].freeze
  FULL_FORMATS = %i[json text headers].freeze
  ALL_FORMATS = [URI_FORMATS, FULL_FORMATS].flatten.freeze

  included do
    # Register supported MIME formats
    # @see 'config/initializers/mime_types.rb' for details
    self.responder = Ext::ApplicationResponder
    respond_to(*URI_FORMATS, only: %i[locations])
    respond_to(*FULL_FORMATS)

    before_action :validate_requested_format!
  end

  # Checks request format and defaults or returns HTTP[406].
  def validate_requested_format!
    return if ALL_FORMATS.include?(request.format.symbol)
    render_error :not_acceptable, 'Requested media format is not acceptable'
  end

  # Checks request format and defaults or returns HTTP[406].
  def validate_provided_format!
    return if request.content_mime_type && FULL_FORMATS.include?(request.content_mime_type.symbol)
    render_error :not_acceptable, 'Provided media format is not acceptable'
  end
end
