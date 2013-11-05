module Backends
  module ResourceTpl
    module Dummy

      # Gets platform- or backend-specific `resource_tpl` mixins which should be merged
      # into Occi::Model of the server. Mixins are identified by their scheme and term,
      # duplicities will be automatically ignored (i.e. will NOT replace existing mixins).
      #
      # @example
      #    collection = resource_tpl_get_all #=> #<Occi::Collection>
      #    collection.mixins  #=> #<Occi::Core::Mixins>
      #
      # @return [Occi::Collection] a collection of `resource_tpl` mixins
      def resource_tpl_get_all
        collection = Occi::Collection.new

        # Load all JSON files in the given directory, these contain
        # JSON rendering of OCCI mixin definitions
        Dir.glob(File.join(@options.model, 'infrastructure', 'resource_tpl', '*.json')) do |file|
          parsed = JSON.parse(File.read(file))
          coll = Occi::Collection.new(parsed)

          collection.merge! coll
        end

        collection
      end

      def resource_tpl_get; end
      def resource_tpl_create; end
      def resource_tpl_delete; end
      def resource_tpl_update; end

    end
  end
end