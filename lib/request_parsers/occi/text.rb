module RequestParsers
  module Occi
    class Text
      def self.parse(media_type, body, headers, path, entity_type, categories)
        Rails.logger.debug "[Parser] [#{self}] Parsing media_type='#{media_type}' " \
                           "body='#{body}' headers=#{headers.inspect} path='#{path}' " \
                           "entity_type='#{entity_type.inspect} categories='#{categories.inspect}'"
        entity_type = entity_type || ::Occi::Core::Resource
        categories = path.include?('-/') || categories
        ::Occi::Parser.parse(media_type, body, categories, entity_type, headers)
      end
    end
  end
end
