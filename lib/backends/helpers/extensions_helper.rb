module Backends
  module Helpers
    # Provides helpers for loading model extensions from JSON
    # files containing OCCI mixins and actions.
    module ExtensionsHelper
      # Returns a collection of custom mixins introduced (and specific for)
      # the enabled backend. Only mixins and actions are allowed.
      #
      # @param backend_type [String] type of the backend
      # @param model_extensions_dir [String] base path for extension retrieval
      # @return [Occi::Collection] collection of extensions (custom mixins and/or actions)
      def read_extensions(backend_type, model_extensions_dir)
        fail Backends::Errors::ResourceRetrievalError, 'Cannot retrieve extensions ' \
                                                       'for an unspecified backend type!' if backend_type.blank?
        fail Backends::Errors::ResourceRetrievalError, 'Cannot retrieve extensions ' \
                                                   'w/o the extensions dir!' if model_extensions_dir.blank?

        collection = Occi::Collection.new
        path = File.join(model_extensions_dir, backend_type, '*.json')

        Dir.glob(path).each do |json_file|
          collection.merge! read_from_json(json_file) if File.readable?(json_file)
        end

        collection
      end
    end
  end
end