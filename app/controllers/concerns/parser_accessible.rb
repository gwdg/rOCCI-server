module ParserAccessible
  extend ActiveSupport::Concern

  # Statically defined supported parsers
  SUPPORTED_PARSERS = [Occi::Core::Parsers::JsonParser, Occi::Core::Parsers::TextParser].freeze

  included do
    delegate :supported_parsers, to: :class
  end

  class_methods do
    # Returns list of supported parser classes.
    #
    # @return [Array] supported parser classes
    def supported_parsers
      SUPPORTED_PARSERS
    end
  end

  # Attempts to parse given `type` of entity or action instances from the current
  # request.
  #
  # @param type [Symbol] expected entity type, use one of `%i(resources links action_instances)`
  # @return [Set] collection of entity instances parsed from current request
  def request_entities(type)
    entities = parser_wrapper { request_parser.send(type, request.raw_post, request.headers) }
    validate_entities! entities
  end

  # @see `request_entities`
  def request_resources
    request_entities :resources
  end

  # @see `request_entities`
  def request_links
    request_entities :links
  end

  # @see `request_entities`
  def request_action_instances
    request_entities :action_instances
  end

  # Attempts to parse mixins from the current request. Mixins must be present in
  # server's own model.
  #
  # @return [Set] collection of mixins from current request
  def request_mixins
    parser_wrapper { request_parser.mixins(request.raw_post, request.headers) }
  end

  # Validates given `Enumerable` with `Occi::Core::Entity`-like objects.
  #
  # @param enum [Enumerable] list of objects
  # @return [Enumerable] given list
  def validate_entities!(enum)
    unless enum.respond_to?(:each)
      raise Errors::InternalError, 'Validation cannot be performed on non-enumerable objects'
    end
    enum.each(&:valid!)
    enum
  rescue ::Occi::Core::Errors::ValidationError => ex
    logger.error "Validation failed: #{ex.class} #{ex.message}"
    raise Errors::ValidationError, ex.message
  end

  # Wraps given block in simple error handling. Intended for use with `request_parser`.
  def parser_wrapper
    yield
  rescue ::Occi::Core::Errors::ParsingError => ex
    logger.error "Request parsing failed: #{ex.class} #{ex.message}"
    raise Errors::ParsingError, ex.message
  end

  # Instantiates parser for the current request. Parser selection is done automatically based on
  # `request.content_mime_type`.
  #
  # @return [Occi::Core::Parsers::BaseParser] parser instance
  def request_parser
    return @_request_parser if @_request_parser

    klass = parser_class(stringy_media_type)
    raise Errors::InternalError, "Parser for #{stringy_media_type} is not available" unless klass

    @_request_parser = klass.new(model: server_model, media_type: stringy_media_type)
  end

  # Returns parser class for the given format.
  #
  # @param format [String] HTTP-compliant format name
  # @return [NillClass] if no parser found
  # @return [Class] parser class
  def parser_class(format)
    supported_parsers.detect { |p| p.parses? format }
  end

  # Returns `String`-like media type specification.
  #
  # @return [String] media type
  def stringy_media_type
    request.content_mime_type.to_s
  end
end
