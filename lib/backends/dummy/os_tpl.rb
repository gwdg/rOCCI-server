module Backends
  module Dummy
    module OsTpl
      # Gets backend-specific `os_tpl` mixins which should be merged
      # into Occi::Model of the server.
      #
      # @example
      #    mixins = os_tpl_list #=> #<Occi::Core::Mixins>
      #    mixins.first #=> #<Occi::Core::Mixin>
      #
      # @return [Occi::Core::Mixins] a collection of mixins
      def os_tpl_list
        read_os_tpl_fixtures
      end

      # Gets a specific os_tpl mixin instance as Occi::Core::Mixin.
      # Term given as an argument must match the term inside
      # the returned Occi::Core::Mixin instance.
      #
      # @example
      #    os_tpl = os_tpl_get('65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf')
      #        #=> #<Occi::Core::Mixin>
      #
      # @param term [String] OCCI term of the requested os_tpl mixin instance
      # @return [Occi::Core::Mixin, nil] a mixin instance or `nil`
      def os_tpl_get(term)
        ###
        # See #os_tpl_list for details on how to create Occi::Core::Mixin instances.
        # Here you simply select a specific instance with a matching term.
        # Since terms must be unique, you should always return at most one instance.
        ###
        found = os_tpl_list.to_a.select { |m| m.term == term }.first
        fail Backends::Errors::ResourceNotFoundError, "Mixin with term #{term.inspect} does not exist!" unless found

        found
      end
    end
  end
end
