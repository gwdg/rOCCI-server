module Backends
  module Ec2
    module Helpers
      module ComputeParseHelper

        def compute_parse_backend_obj(backend_compute)
          compute = Occi::Infrastructure::Compute.new

          compute.attributes['occi.core.id'] = backend_compute[:instance_id]
          compute.mixins << "#{@options.backend_scheme}/occi/infrastructure/os_tpl##{os_tpl_list_image_to_term(backend_compute)}"
          compute.mixins << "http://schemas.ec2.aws.amazon.com/occi/infrastructure/resource_tpl##{resource_tpl_list_itype_to_term(backend_compute[:instance_type])}"

          # include state information and available actions
          result = compute_parse_state(backend_compute)
          compute.state = result.state
          result.actions.each { |a| compute.actions << a }

          # include storage and network links
          result = compute_parse_links(backend_compute, compute)
          result.each { |link| compute.links << link }

          compute
        end

        private

        def compute_parse_state(backend_compute)
          result = Hashie::Mash.new

          # In EC2:
          #   0 : pending
          #   16 : running
          #   32 : shutting-down
          #   48 : terminated
          #   64 : stopping
          #   80 : stopped
          case backend_compute[:state][:code].to_i
          when 16
            result.state = 'active'
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#stop http://schemas.ogf.org/occi/infrastructure/compute/action#restart http://schemas.ogf.org/occi/infrastructure/compute/action#suspend|
          when 80
            result.state = 'suspended'
            result.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
          when 0, 64
            result.state = 'waiting'
            result.actions = []
          else
            result.state = 'inactive'
            result.actions = []
          end

          result
        end

        def compute_parse_links(backend_compute, compute)
          result = []

          result << compute_parse_links_storage(backend_compute, compute)
          result << compute_parse_links_network(backend_compute, compute)
          result.flatten!

          result.compact
        end

        def compute_parse_links_storage(backend_compute, compute)
          #
        end

        def compute_parse_links_network(backend_compute, compute)
          #
        end

      end
    end
  end
end
