module Ext
  class RenderableError
    HEADERS_KEY = 'X-OCCI-Error'.freeze

    attr_accessor :code, :message

    def initialize(code, message)
      @code = code
      @message = message || 'Unspecified error'
    end

    def to_json
      { status: code, error: message }.to_json
    end

    def to_headers
      { HEADERS_KEY => to_s }
    end

    def to_s
      message
    end
    alias to_text to_s
  end
end
