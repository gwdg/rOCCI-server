module Renderable
  extend ActiveSupport::Concern

  # Format constants
  URI_FORMATS = %i[uri_list].freeze
  FULL_FORMATS = %i[json text headers].freeze
  ALL_FORMATS = [URI_FORMATS, FULL_FORMATS].flatten.freeze
  UBIQUITOUS_FORMATS = %w[*/*].freeze
  DEFAULT_FORMAT_SYM = FULL_FORMATS.first

  included do
    # Register supported MIME formats
    # @see 'config/initializers/mime_types.rb' for details
    self.responder = ApplicationResponder
    respond_to(*URI_FORMATS, only: %i[locations])
    respond_to(*FULL_FORMATS)

    before_action :validate_format!
  end

  # Checks request format and defaults or returns HTTP[406].
  def validate_format!
    if UBIQUITOUS_FORMATS.include?(request.format.to_s)
      logger.debug "Changing ubiquitous format #{request.format} to #{DEFAULT_FORMAT_SYM}"
      request.format = DEFAULT_FORMAT_SYM
    end

    return if ALL_FORMATS.include?(request.format.symbol)
    render_error 406, 'Requested media format is not acceptable'
  end
end
