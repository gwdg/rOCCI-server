module OCCI
  module Backend
    class CloudStack
      module Compute
        def compute_register_all_instances(client)
          # FIXME: Fix the argument
          backend_instance_objects = client.list_virtual_machines 'listall'=>'true'

          backend_instance_objects['virtualmachine'].each do |instance|
            compute_parse_backend_instances client, instance
          end
        end

        def compute_parse_backend_instances(client, backend_instance)
          compute_kind = @model.get_by_id 'http://schemas.ogf.org/occi/infrastructure#compute'
          id = backend_instance['id']

          compute = OCCI::Core::Resource.new(compute_kind.type_identifier)

          compute.id = id
          compute.title = backend_instance['name']
          
          compute.attributes.occi!.compute!.account   = backend_instance['account'] if backend_instance['account']
          compute.attributes.occi!.compute!.domain    = backend_instance['domain'] if backend_instance['domain']
          compute.attributes.occi!.compute!.cpunumber = backend_instance['cpunumber'] if backend_instance['cpunumber']
          compute.attributes.occi!.compute!.cpuspeed  = backend_instance['cpuspeed'] if backend_instance['cpuspeed']
          compute.attributes.occi!.compute!.cpuused   = backend_instance['cpuused'] if backend_instance['cpuused']
          compute.attributes.occi!.compute!.memory    = backend_instance['memory'] if backend_instance['memory']
          compute.attributes.occi!.compute!.haenable  = backend_instance['passwordenabled'] if backend_instance['passwordenabled']

          compute.mixins << client.list_service_offerings('id'=>"#{backend_instance['serviceofferingid']}").reject!{ |k| k == 'count'  } if backend_instance['serviceofferingid']

          compute.mixins << client.list_templates('templatefilter'=>'featured', 'id'=>"#{backend_instance['templateid']}").reject!{ |k| k == 'count'  } if backend_instance['templateid']

          compute.mixins << client.list_zones('id'=>"#{backend_instance['zoneid']}").reject!{ |k| k == 'count'  } if backend_instance['zoneid']

          compute.mixins.uniq!

          compute.check @model

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
          OCCI::Log.debug "Deploying CloudStack instance : #{compute.inspect}"

          os_tpl = "" # FIXME: fallback os template
          service_offering = "" # FIXME: fallback service offering

          os_tpl = compute.mixins.select { |mixin|
            OCCI::Log.debug "Compute deploy found mixin: #{mixin}"
            if mixin.kind_of? String
              mixin = @model.get_by_id(mixin)
            end

            mixin.related_to? "http://schemas.ogf.org/occi/infrastructure#os_tpl" if mixin
          }.compact.first

          service_offering = compute.mixins.select { |mixin|
            OCCI::Log.debug "Compute deploy found mixin: #{mixin}"
            if mixin.kind_of? String
              mixin = @model.get_by_id(mixin)
            end

            mixin.related_to? "http://schemas.ogf.org/occi/infrastructure#compute_offering" if mixin
          }.compact.first

          available_zone = compute.mixins.select { |mixin|
            OCCI::Log.debug "Compute deploy found mixin: #{mixin}"
            if mixin.kind_of? String
              mixin = @model.get_by_id(mixin)
            end

            mixin.related_to? "http://schemas.ogf.org/occi/infrastructure#available_zone" if mixin
          }.compact.first

          async_job = client.deploy 'serviceofferingid'=>"#{service_offering.term}",
                                    'templateid'       =>"#{os_tpl.term}",
                                    'zoneid'           =>"#{available_zone.term}"

          result = query_async_result client, async_job['jobid']

          OCCI::Log.debug "Return code from CloudStack #{result}" if result != nil

          OCCI::Log.debug "OCCI Compute resource #{result['virtualmachine']}"

          compute_set_state result['virtualmachine'], compute

          OCCI::Log.debug "CloudStack automatically triggers action start for Virtual Machines"

          OCCI::Log.debug "Changing state to started"
        end

        def compute_update_state(client, compute)
          OCCI::Log.debug "Updating CloudStack instance status."

          backend_instance = get_backend_instance client, compute
          
          compute_set_state result['virtualmachine'], compute
        end

        def compute_delete(client, compute)
          OCCI::Log.debug "Deleting CloudStack instance."
        end

        def compute_start(client, compute, parameters)
          OCCI::Log.debug "Starting CloudStack instance."

          backend_instance = get_backend_instance client, compute

          async_job = client.start_virtual_machine 'id'=>"#{backend_instance['id']}"

          result = query_async_result async_job['jobid']

          compute_set_state result['virtualmachine'], compute

          OCCI::Log.debug "Changing state to Running"
        end

        def compute_stop(client, compute, parameters)
          OCCI::Log.debug "Stoping CloudStack instance."
          backend_instance = get_backend_instance client, compute

          async_job = client.stop_virtual_machine 'id'=>"#{backend_instance['id']}"

          result = query_async_result async_job['jobid']

          compute_set_state result['virtualmachine'], compute

          OCCI::Log.debug "Changing state to Stopped"
        end

        def compute_restart(client, compute, parameters)
          OCCI::Log.debug "Restarting CloudStack instance."
          backend_instance = get_backend_instance client, compute

          async_job = client.reboot_virtual_machine 'id'=>"#{backend_instance['id']}"

          result = query_async_result async_job['jobid']

          compute_set_state result['virtualmachine'], compute

          OCCI::Log.debug "Changing state to Running"
        end

        def get_backend_instance(client, compute)
          backend_instance = client.list_virtual_machine 'id'=>"#{compute.id}"

          raise OCCI::BackendError, "No backend instance be found" if !backend_instance

          backend_instance
        end

        def compute_parse_links(client, compute, backend_instance)
          # FIXME: create links for all storage instances
          # create links for all network instances
          # backend_instance['nic'].each do |nic|
          #   OCCI::Log.debug("Network Backend ID: #{nic['NETWORK_ID']}")
          #   networkinterface_kind = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#networkinterface')
          #   link                  = OCCI::Core::Link.new(networkinterface_kind.type_identifier)
          #   link.id               = nic['id']
          #   network_kind          = @model.get_by_id('http://schemas.ogf.org/occi/infrastructure#network')
          #   network_id            = nic['networkid']
          # end
        end
      end
    end
  end
end
