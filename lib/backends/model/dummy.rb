module Backends
  module Model
    module Dummy

      # Gets platform- or backend-specific extensions which should be merged
      # into Occi::Model of the server.
      #
      # @example
      #    collection = model_get_extensions #=> #<Occi::Collection>
      #    collection.kinds   #=> #<Occi::Core::Kinds>
      #    collection.mixins  #=> #<Occi::Core::Mixins>
      #    collection.actions #=> #<Occi::Core::Actions>
      #
      # @return [Occi::Collection] a collection of extensions containing kinds, mixins and actions
      def model_get_extensions
        collection = Occi::Collection.new

        # Load all JSON files in the given directory, these contain
        # JSON rendering of OCCI kind/mixin/action definitions
        Dir.glob(File.join(@options.model, '**', '*.json')) do |file|
          parsed = JSON.parse(File.read(file))
          coll = Occi::Collection.new(parsed)

          collection.merge! coll
        end

        collection
      end

    end
  end
end