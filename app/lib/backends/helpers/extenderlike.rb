module Backends
  module Helpers
    module Extenderlike
      # Fills the given model instance with extensions (i.e., mixins) defined
      # by the specific backend. This usually includes `resource_tpl`s, `os_tpl`s,
      # `region`s, `availability_zone`s, etc.
      #
      # @param model [Occi::Core::Model] model instance to extend
      # @return [Occi::Core::Model] extended model instance (modified original)
      def populate!(model)
        model
      end
    end
  end
end
