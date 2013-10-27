module Occi
  module Extensions
    module Collection

      def to_occi_header(*args)
        self.to_header
      end

      def to_occi_json(*args)
        self.to_json
      end

      def to_occi_xml(*args)
        self.to_xml
      end

      def to_xml(*args)
        raise 'Not implemented!'
      end

    end
  end
end