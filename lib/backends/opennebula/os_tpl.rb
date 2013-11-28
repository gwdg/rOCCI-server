module Backends
  module Opennebula
    module OsTpl

      OS_TPL_TERM_PREFIX = "uuid_"

      # Gets backend-specific `os_tpl` mixins which should be merged
      # into Occi::Model of the server.
      #
      # @example
      #    mixins = os_tpl_list #=> #<Occi::Core::Mixins>
      #    mixins.first #=> #<Occi::Core::Mixin>
      #
      # @return [Occi::Core::Mixins] a collection of mixins
      def os_tpl_list
        os_tpl = Occi::Core::Mixins.new
        backend_tpl_pool = ::OpenNebula::TemplatePool.new(@client)
        backend_tpl_pool.info_all
        check_retval(backend_tpl_pool, Backends::Errors::ResourceRetrievalError)

        backend_tpl_pool.each do |backend_tpl|
          related = %w|http://schemas.ogf.org/occi/infrastructure#os_tpl|
          term    = "#{OS_TPL_TERM_PREFIX}#{backend_tpl['ID']}"
          scheme  = "#{@options.backend_scheme}/occi/infrastructure/os_tpl#"
          title   = backend_tpl['NAME']

          os_tpl << Occi::Core::Mixin.new(scheme, term, title, nil, related)
        end

        os_tpl
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
        # TODO: make it more efficient!
        os_tpl_list.to_a.select { |m| m.term == term }.first
      end

    end
  end
end