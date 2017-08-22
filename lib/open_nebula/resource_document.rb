require 'opennebula/document_json'

module OpenNebula
  class ResourceDocument < DocumentJSON
    # Using an unlikely number to avoid collisions
    DOCUMENT_TYPE = 999

    # OCCI identifier separator
    ID_SEPARATOR = '#'.freeze

    attr_reader :body

    # @return [String] `resource_tpl` term
    def term
      identifier.split(ID_SEPARATOR).last
    end

    # @return [String] `resource_tpl` schema
    def schema
      "#{identifier.split(ID_SEPARATOR).first}#{ID_SEPARATOR}"
    end

    private

    # :nodoc:
    def method_missing(m, *args, &block)
      m = m.to_s
      return body.fetch(m) if body.key?(m)
      super
    end

    # :nodoc:
    def respond_to_missing?(method_name, include_private = false)
      body.key?(method_name.to_s) || super
    end
  end
end
