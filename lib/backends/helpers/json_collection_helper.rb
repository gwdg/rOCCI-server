module Backends
  module Helpers
    module JsonCollectionHelper
      def read_from_json(path)
        collection = Occi::Collection.new
        collection.model = nil

        # Load all JSON files in the given directory, these contain
        # JSON rendering of OCCI kind/mixin/action definitions
        @logger.debug "[#{self.class}] Getting fixtures from #{path}"
        parsed = JSON.parse(File.read(path))
        collection.merge! Occi::Collection.new(parsed)

        collection
      end
    end
  end
end
