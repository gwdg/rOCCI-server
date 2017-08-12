module Backends
  module Helpers
    module ResourceTplLocatable
      # Locates `resource_tpl` mixin by matching size. Returns `nil` if no matching mixin is found in the
      # active `server_model`. Size matching is performed based on numerical values assigned to `virtual_machine`
      # such as CPU, VPCU, MEMORY, and DISK SIZE.
      #
      # @param virtual_machine [Object] machine to match
      # @param comparable_attributes [Hash] maps attributes between `virtual_machine` and `resource_tpl`
      # @return [NilClass] if nothing found
      # @return [Occi::Core::Mixin] if resource_tpl found
      def resource_tpl_by_size(virtual_machine, comparable_attributes)
        return unless virtual_machine
        server_model.find_resource_tpls.detect do |resource_tpl|
          comparable_attributes.reduce(true) do |match, (key, val)|
            tpl_val = resource_tpl[key] ? resource_tpl[key].default : nil
            match && val.call(virtual_machine, tpl_val)
          end
        end
      end
    end
  end
end
