module Backends
  module Dummy
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
        read_resource_tpl_fixtures
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
        ###
        # See #resource_tpl_list for details on how to create Occi::Core::Mixin instances.
        # Here you simply select a specific instance with a matching term.
        # Since terms must be unique, you should always return at most one instance.
        ###
        found = resource_tpl_list.to_a.select { |m| m.term == term }.first
        fail Backends::Errors::ResourceNotFoundError, "Mixin with term #{term.inspect} does not exist!" unless found

        found
      end
    end
  end
end
