module BackendApi
  module OsTpl

    # Gets platform- or backend-specific `os_tpl` mixins which should be merged
    # into Occi::Model of the server.
    #
    # @example
    #    collection = os_tpl_get_all #=> #<Occi::Collection>
    #    collection.mixins  #=> #<Occi::Core::Mixins>
    #
    # @return [Occi::Collection] a collection of mixins
    def os_tpl_get_all
      @backend_instance.os_tpl_get_all
    end

    def os_tpl_get; end

  end
end