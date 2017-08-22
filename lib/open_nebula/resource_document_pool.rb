require 'opennebula/document_pool_json'

module OpenNebula
  class ResourceDocumentPool < DocumentPoolJSON
    # Using an unlikely number to avoid collisions
    DOCUMENT_TYPE = 999

    # @see `::OpenNebula::DocumentPoolJSON`
    def factory(element_xml)
      s_template = ResourceDocument.new(element_xml, @client)
      s_template.load_body
      s_template
    end
  end
end
