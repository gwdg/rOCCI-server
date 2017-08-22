module Backends
  module Opennebula
    module Helpers
      module Counter
        # Counts XML elements matching XPATH.
        #
        # @param object [OpenNebula::XMLElement] element to count in
        # @param xpath [String] XPATH to look for
        # @return [Fixnum] numbers of elements matching given XPATH
        def self.xml_elements(object, xpath)
          count = 0
          object.each_xpath(xpath) { count += 1 }
          count
        end
      end
    end
  end
end
