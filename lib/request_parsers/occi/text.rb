module RequestParsers
  module Occi
    class Text

      def self.parse(media_type, body, headers, path)
        Rails.logger.debug "[Parser] [#{self}] Parsing media_type='#{media_type}' body='#{body}' headers=#{headers.inspect} path='#{path}'"
        ::Occi::Parser.parse(media_type, body, path.include?('-/'), ::Occi::Core::Resource, headers)
      end

    end
  end
end