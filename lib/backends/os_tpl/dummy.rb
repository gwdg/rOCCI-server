module Backends
  module OsTpl
    module Dummy

      # Gets backend-specific `os_tpl` mixins which should be merged
      # into Occi::Model of the server.
      #
      # @example
      #    mixins = os_tpl_get_all #=> #<Occi::Core::Mixins>
      #    mixins.first #=> #<Occi::Core::Mixin>
      #
      # @return [Occi::Core::Mixins] a collection of mixins
      def os_tpl_get_all
        collection = Occi::Collection.new

        # Load all JSON files in the given directory, these contain
        # JSON rendering of OCCI mixin definitions
        Dir.glob(File.join(@options.model_extensions_dir, 'infrastructure', 'os_tpl', '*.json')) do |file|
          parsed = JSON.parse(File.read(file))
          coll = Occi::Collection.new(parsed)

          collection.merge! coll
        end if @options.model_extensions_dir

        collection.mixins
      end

    end
  end
end