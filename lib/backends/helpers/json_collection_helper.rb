module Backends
  module Helpers
    # Helps with loading OCCI collections from JSON files.
    module JsonCollectionHelper
      # Reads an OCCI-compliant collection from a JSON file.
      #
      # @param path [String] readable JSON file
      # @return [::Occi::Collection] parsed collection instance
      def read_from_json(path)
        fail "Couldn't read a collection from #{path.inspect}! " \
             "File not readable!" unless File.readable?(path)
        collection = ::Occi::Collection.new
        collection.model = nil

        # Load all JSON files in the given directory, these contain
        # JSON rendering of OCCI kind/mixin/action definitions
        @logger.debug "[#{self.class}] Getting fixtures from #{path}"
        parsed = JSON.parse(File.read(path))
        collection.merge! ::Occi::Collection.new(parsed)

        collection
      end
    end
  end
end
