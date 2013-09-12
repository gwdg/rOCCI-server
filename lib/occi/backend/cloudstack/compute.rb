module OCCI
  module Backend
    class CloudStack
      module Compute
        def compute_register_all_instances(client)
          # FIXME: Fix the argument
          backend_instance_objects = client.list_virtual_machines 'listall' => 'true'

          backend_instance_objects['virtualmachine'].each do |instance|
            compute_parse_backend_instances client, instance
          end
        end

        def compute_parse_backend_instances(client, backend_instance)
          compute_kind = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#compute')
          id = backend_instance['id']

          compute = OCCI::Core::Resource.new(compute_kind.type_identifier)

          compute.id = id
          compute.title = backend_instance['name']
          compute.attributes.occi!.compute!.account = backend_instance['account'] if backend_instance['account']
          compute.attributes.occi!.compute!.domain = backend_instance['domain'] if backend_instance['domain']
          compute.attributes.occi!.compute!.zone = backend_instance['zone'] if backend_instance['zone']
          compute.attributes.occi!.compute!.cpunumber = backend_instance['cpunumber'] if backend_instance['cpunumber']
          compute.attributes.occi!.compute!.cpuspeed = backend_instance['cpuspeed'] if backend_instance['cpuspeed']
          compute.attributes.occi!.compute!.cpuused = backend_instance['cpuused'] if backend_instance['cpuused']
          compute.attributes.occi!.compute!.memory = backend_instance['memory'].to_f/1000 if backend_instance['memory']
          compute.attributes.occi!.compute!.haenable = backend_instance['haenable'] if backend_instance['haenable']
          compute.attributes.occi!.compute!.templatename = backend_instance['templatename'] if backend_instance['templatename']
          compute.attributes.occi!.compute!.serviceofferingname = backend_instance['serviceofferingname'] if backend_instance['serviceofferingname']
          compute.check(@model)

          compute_set_state backend_instance, compute

          compute_parse_links client, compute, backend_instance

          compute_kind.entities << compute unless compute_kind.entities.select { |entity| entity.id == compute.id }.any?
        end

        def compute_set_state(backend_instance, compute)
          OCCI::Log.debug("current VM state is: #{backend_instance['state']}")
          case backend_instance['state']
          when 'Running' then
            compute.attributes.occi!.compute!.state = backend_instance['state']
            compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#stop http://schemas.ogf.org/occi/infrastructure/compute/action#restart|
          when 'Stopped'
            compute.attributes.occi!.compute!.state = backend_instance['state']
            compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
          else
          end
        end

        def compute_deploy(client, compute)
          OCCI::Log.debug("Deploying CloudStack instance.")
        end

        def compute_delete(client, compute)
          OCCI::Log.debug("Deleting CloudStack instance.")
        end

        def compute_start(client, compute, parameters)
          OCCI::Log.debug("Starting CloudStack instance.")
        end

        def compute_stop(client, compute, parameters)
          OCCI::Log.debug("Stoping CloudStack instance.")
        end

        def compute_restart(client, compute, parameters)
          OCCI::Log.debug("Restarting CloudStack instance.")
        end

        def compute_parse_links(client, compute, backend_instance)
          # FIXME: create links for all storage instances
          # create links for all network instances
          backend_instance['nic'].each do |nic|
            OCCI::Log.debug("Network Backend ID: #{nic['NETWORK_ID']}")
            networkinterface_kind = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#networkinterface')
            link                  = OCCI::Core::Link.new(networkinterface_kind.type_identifier)
            link.id               = nic['id']
            network_kind          = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#network')
            network_id            = nic['networkid']
          end
        end

        def check_result(client, backend_instance)
        end
      end
    end
  end
end
