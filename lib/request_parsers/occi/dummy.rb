module RequestParsers
  module Occi
    class Dummy

      def self.parse(media_type, body, headers, path)
        Rails.logger.debug "[Parser] [#{self}] Parsing media_type='#{media_type}' body='#{body}' headers=#{headers.inspect} path='#{path}'"
        ::Occi::Collection.new
      end

    end
  end
end