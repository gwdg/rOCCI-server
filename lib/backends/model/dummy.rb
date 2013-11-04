module Backends
  module Model
    module Dummy

      def model_get_extensions
        collection = Occi::Collection.new

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