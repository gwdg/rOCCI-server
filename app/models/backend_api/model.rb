module BackendApi
  module Model

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
      @backend_instance.model_get_extensions
    end

  end
end