module BackendApi
  module ResourceTpl

    # Gets platform- or backend-specific `resource_tpl` mixins which should be merged
    # into Occi::Model of the server.
    #
    # @example
    #    collection = resource_tpl_get_all #=> #<Occi::Collection>
    #    collection.mixins  #=> #<Occi::Core::Mixins>
    #
    # @return [Occi::Collection] a collection of mixins
    def resource_tpl_get_all
      @backend_instance.resource_tpl_get_all
    end

  end
end