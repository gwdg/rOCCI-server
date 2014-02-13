module BackendApi
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
      os_tpl = @backend_instance.os_tpl_list || Occi::Core::Mixins.new
      os_tpl.each { |m| m.location = "/mixin/os_tpl/#{m.term}/" }
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
      fail Errors::ArgumentError, '\'term\' is a mandatory argument' if term.blank?
      os_tpl = @backend_instance.os_tpl_get(term)
      os_tpl.location = "/mixin/os_tpl/#{os_tpl.term}/" if os_tpl
      os_tpl
    end
  end
end
