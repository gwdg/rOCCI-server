module Backends
  module Opennebula
    module ResourceTpl

      # Gets platform- or backend-specific `resource_tpl` mixins which should be merged
      # into Occi::Model of the server.
      #
      # @example
      #    mixins = resource_tpl_list #=> #<Occi::Core::Mixins>
      #    mixins.first  #=> #<Occi::Core::Mixin>
      #
      # @return [Occi::Core::Mixins] a collection of mixins
      def resource_tpl_list
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

      # Gets a specific resource_tpl mixin instance as Occi::Core::Mixin.
      # Term given as an argument must match the term inside
      # the returned Occi::Core::Mixin instance.
      #
      # @example
      #    resource_tpl = resource_tpl_get('65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf')
      #        #=> #<Occi::Core::Mixin>
      #
      # @param term [String] OCCI term of the requested resource_tpl mixin instance
      # @return [Occi::Core::Mixin, nil] a mixin instance or `nil`
      def resource_tpl_get(term)
        # TODO: impl
        raise Backends::Errors::StubError, "#{__method__} is just a stub!"
      end

    end
  end
end