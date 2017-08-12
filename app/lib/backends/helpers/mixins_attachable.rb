module Backends
  module Helpers
    module MixinsAttachable
      # Attempts to look up and attach a mixin to given instance. Mixin is looked up
      # based on `term` in a collection defined by `type`. If no such mixin is found,
      # nothing happens.
      #
      # @example
      #    attach_optional_mixin! entity, 'my_os', :os_tpl
      #
      # @param entity [Occi::Core::Entity] instance to add the mixin to, if found
      # @param term [String] mixin term to look up
      # @param type [Symbol] mixin type, should correspond to `find` methods on `Occi::*::Model`
      def attach_optional_mixin!(entity, term, type)
        mxn = server_model.send("find_#{type}s").detect { |m| m.term == term }
        return unless mxn
        entity << mxn
      end
    end
  end
end
