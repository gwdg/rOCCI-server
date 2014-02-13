module RequestParsers
  module Occi
    class Text
      def self.parse(media_type, body, headers, path, entity_type = ::Occi::Core::Resource)
        Rails.logger.debug "[Parser] [#{self}] Parsing media_type='#{media_type}' body='#{body}' headers=#{headers.inspect} path='#{path}' entity_type='#{entity_type.inspect}"
        ::Occi::Parser.parse(media_type, body, path.include?('-/'), entity_type, headers)
      end
    end
  end
end
