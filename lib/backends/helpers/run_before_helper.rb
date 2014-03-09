module Backends
  module Helpers
    module RunBeforeHelper
      module ClassMethods
        def run_before(names, method, is_authn = false)
          names.each do |name|
            next if is_authn && !needs_authn?(name)

            m = instance_method(name)
            define_method(name) do |*args, &block|
              send(method.to_sym)
              m.bind(self).call(*args, &block)
            end
          end
        end

        def needs_authn?(name)
          name.to_s.match(/^(compute_|network_|os_tpl_|resource_tpl_|storage_).+/)
        end
      end
    end
  end
end
