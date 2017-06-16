class RenderableError
  HEADERS_KEY = 'X-OCCI-Error'.freeze

  attr_accessor :code, :message

  def initialize(code, message)
    @code = code
    @message = message || 'Unspecified error'
  end

  def to_json
    { code: code, message: message }.to_json
  end

  def to_headers
    { HEADERS_KEY => to_s }
  end

  def to_s
    "#{code} #{message}"
  end
  alias_method :to_text, :to_s
end
