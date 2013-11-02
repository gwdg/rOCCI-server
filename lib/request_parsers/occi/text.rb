module RequestParsers
  module Occi
    class Text

      def self.parse(media_type, body, headers, path)
        ::Occi::Collection.new
      end

    end
  end
end