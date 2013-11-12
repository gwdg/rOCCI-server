module BackendApi
  module OsTpl

    # Gets backend-specific `os_tpl` mixins which should be merged
    # into Occi::Model of the server.
    #
    # @example
    #    mixins = os_tpl_get_all #=> #<Occi::Core::Mixins>
    #    mixins.first #=> #<Occi::Core::Mixin>
    #
    # @return [Occi::Core::Mixins] a collection of mixins
    def os_tpl_get_all
      @backend_instance.os_tpl_get_all || Occi::Core::Mixins.new
    end

  end
end