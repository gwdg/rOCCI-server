module Backends
  module OsTpl
    module Dummy

      # Gets platform- or backend-specific `os_tpl` mixins which should be merged
      # into Occi::Model of the server. Mixins are identified by their scheme and term,
      # duplicities will be automatically ignored (i.e. will NOT replace existing mixins).
      #
      # @example
      #    collection = os_tpl_get_all #=> #<Occi::Collection>
      #    collection.mixins  #=> #<Occi::Core::Mixins>
      #
      # @return [Occi::Collection] a collection of `os_tpl` mixins
      def os_tpl_get_all
        collection = Occi::Collection.new

        # Load all JSON files in the given directory, these contain
        # JSON rendering of OCCI mixin definitions
        Dir.glob(File.join(@options.model_extensions_dir, 'infrastructure', 'os_tpl', '*.json')) do |file|
          parsed = JSON.parse(File.read(file))
          coll = Occi::Collection.new(parsed)

          collection.merge! coll
        end if @options.model_extensions_dir

        collection
      end

    end
  end
end