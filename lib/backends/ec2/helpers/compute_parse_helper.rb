module Backends
  module Ec2
    module Helpers
      module ComputeParseHelper

        def compute_parse_backend_obj(backend_compute)
          compute = Occi::Infrastructure::Compute.new

          compute.attributes['occi.core.id'] = backend_compute[:instance_id]
          compute.mixins << "#{@options.backend_scheme}/occi/infrastructure/os_tpl##{os_tpl_list_image_to_term(backend_compute)}"
          compute.mixins << "http://schemas.ec2.aws.amazon.com/occi/infrastructure/resource_tpl##{backend_compute[:instance_type]}"

          compute
        end

      end
    end
  end
end
