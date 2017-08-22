require 'opennebula/xml_element'

module OpenNebula
  class XMLElement
    XPATH_SEPARATOR = '/'.freeze

    # Assigns `value` to element specified by `xpath`. Element may or may not exist prior to modification.
    #
    # @param xpath [String] xpath to existing value
    # @param value [Object] new value
    def modify_element(xpath, value)
      xpath, key = xpath_parts(xpath)
      modify_element(xpath, '') unless self[xpath]

      delete_element "#{xpath}#{XPATH_SEPARATOR}#{key}"
      add_element xpath, key => value
    end

    private

    # Splits `xpath` into parts by separating the last element.
    #
    # @example
    #    xpath_parts 'TEMPLATE/CONTEXT'           # => ['TEMPLATE', 'CONTEXT']
    #    xpath_parts 'TEMPLATE/CONTEXT/USER_DATA' # => ['TEMPLATE/CONTEXT', 'USER_DATA']
    #
    # @param xpath [String] xpath to split
    # @return [Array] array with last element (last) and the rest (first)
    def xpath_parts(xpath)
      parts = xpath.split(XPATH_SEPARATOR)
      raise 'Only XPATH with two or three elements is supported' unless parts.count.between?(2, 3)
      last = parts.slice!(-1)
      [parts.join(XPATH_SEPARATOR), last]
    end
  end
end
