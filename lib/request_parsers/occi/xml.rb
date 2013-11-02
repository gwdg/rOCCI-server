module RequestParsers
  module Occi
    class XML

      def self.parse(media_type, body, headers, path)
        ::Occi::Collection.new
      end

    end
  end
end