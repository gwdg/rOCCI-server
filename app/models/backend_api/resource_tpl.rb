module BackendApi
  module ResourceTpl

    # Gets platform- or backend-specific `resource_tpl` mixins which should be merged
    # into Occi::Model of the server.
    #
    # @example
    #    mixins = resource_tpl_get_all #=> #<Occi::Core::Mixins>
    #    mixins.first  #=> #<Occi::Core::Mixin>
    #
    # @return [Occi::Core::Mixins] a collection of mixins
    def resource_tpl_get_all
      @backend_instance.resource_tpl_get_all || Occi::Core::Mixins.new
    end

  end
end