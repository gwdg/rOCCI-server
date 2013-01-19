##############################################################################
#  Copyright 2011 Service Computing group, TU Dortmund
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
##############################################################################

##############################################################################
# Description: Fogio Openstack Backend
# Author(s): Maik Srba
##############################################################################

require 'occi/log'
require "base64"

module OCCI
  module Backend
    class Fogio
      module Openstack
        class Compute

          attr_accessor :model

          def initialize(model)
            @model = model

            initUUIDMatching
          end

          def initUUIDMatching
            @pstore = PStore.new("occi_uuid_matching")
            @pstore.transaction do
              @pstore['compute_openstack'] ||= {}
            end

            @pstore.transaction(read_only=true) do
              @uuid_matching = @pstore['compute_openstack']
            end
          end

          def storeUUID(uuid, openstack_uuid)
            @uuid_matching[openstack_uuid] = uuid
            @pstore.transaction do
              @pstore['compute_openstack'] = @uuid_matching
            end
          end

          def parse_backend_object(client, backend_object)
            initUUIDMatching
            kind = @model.get_by_id("http://schemas.ogf.org/occi/infrastructure#compute")

            flavor = client.flavors.get backend_object.attributes[:flavor]['id']

            compute = OCCI::Core::Resource.new(kind.type_identifier)
            compute.mixins << 'http://openstack.org/occi/infrastructure#compute'

            id = backend_object.attributes[:id]  #metadata

            compute.id = @uuid_matching[id]

            if compute.id.nil? || compute.id.length <= 0
              compute.id = UUIDTools::UUID.timestamp_create.to_s
              storeUUID compute.id, id
            end

            compute.title = backend_object.attributes[:name]
            #compute.summary = #metadata
            #
            compute.attributes.occi!.compute!.cores = flavor.attributes[:vcpus]
            #compute.attributes.occi!.compute!.architecture = "x64" if backend_object['TEMPLATE/ARCHITECTURE'] == "x86_64"
            #compute.attributes.occi!.compute!.architecture = "x86" if backend_object['TEMPLATE/ARCHITECTURE'] == "i686"
            compute.attributes.occi!.compute!.memory = flavor.attributes[:ram]

            compute.attributes.org!.openstack!.compute!.ephemeral   = flavor.attributes[:ephemeral]
            compute.attributes.org!.openstack!.compute!.flavor_id   = flavor.attributes[:id]
            compute.attributes.org!.openstack!.compute!.image_id    = backend_object.attributes[:image]["id"]
            compute.attributes.org!.openstack!.compute!.task_state  = backend_object.attributes[:os_ext_sts_task_state] if !backend_object.attributes[:os_ext_sts_task_state].nil?
            compute.attributes.org!.openstack!.compute!.power_state = backend_object.attributes[:os_ext_sts_power_state]
            compute.attributes.org!.openstack!.compute!.created     = backend_object.attributes[:created].to_s
            compute.attributes.org!.openstack!.compute!.updated     = backend_object.attributes[:updated].to_s
            compute.attributes.org!.openstack!.compute!.accessIPv4  = backend_object.attributes[:accessIPv4].to_s if backend_object.attributes[:accessIPv4].to_s.length > 0
            compute.attributes.org!.openstack!.compute!.accessIPv6  = backend_object.attributes[:accessIPv6].to_s if backend_object.attributes[:accessIPv6].to_s.length > 0

            compute.check(@model)

            set_state backend_object, compute

            parse_links client, backend_object, compute

            kind.entities << compute unless kind.entities.select { |entity| entity.id == compute.id }.any?

          end

          def parse_links client, backend_object, compute
            #network

            #storage
          end

          def set_state(backend_object, compute)
            initUUIDMatching
            backend_state = backend_object.attributes[:os_ext_sts_vm_state].downcase

            OCCI::Log.debug("current VM state is: #{backend_state}")
            case backend_state
              when "active" then
                compute.attributes.occi!.compute!.state = "active"
                compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#stop http://schemas.ogf.org/occi/infrastructure/compute/action#restart http://schemas.ogf.org/occi/infrastructure/compute/action#suspend|
              when "build", "deleted", "hard_reboot", "password", "reboot", "rebuild", "rescue", "resize", "revert_resize", "shutoff", "verify_resize" then
                compute.attributes.occi!.compute!.state = "inactive"
                compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#restart|
              when "suspend" then
                compute.attributes.occi!.compute!.state = "suspended"
                compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
              when "error" then
                compute.attributes.occi!.compute!.state = "error"
                compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
              else
                compute.attributes.occi!.compute!.state = "inactive"
                compute.actions                         = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
            end
          end

          def register_all_instances(client)

            client.servers.each do |backend_object|
              parse_backend_object client, backend_object
            end
          end

          def deploy(client, compute)
            OCCI::Log.debug "Deploying #{compute.inspect}"

            compute.id = UUIDTools::UUID.timestamp_create.to_s

            #simulation_id = compute.attributes.org.cloud4E.service.simulation.id;
            simulation_id = ""

            image_ref = "05cb3f9f-0a60-46c8-8954-176047763aa5"
            flavor_id = 1

            if(!simulation_id.nil? && simulation_id.to_s.length > 0)
              image_ref = simulation_id
            end

            file = {"contents" => compute.id, "path" => "home/occi.info"}

            personality = []
            personality << file

            options = {
                "metadata" => {"test_key" => "value"},
                "personality" => personality,
                "adminPass" => "cloud4e"
            }

            server = client.create_server compute.title, image_ref, flavor_id, options

            storeUUID compute.id, server.body["server"]["id"]

            start(client, compute)
          end

          def delete(client, compute)

          end

          def start(client, compute, parameters=nil)

          end

          def stop(client, compute, parameters=nil)

          end

          def restart(client, compute, parameters=nil)

          end

          def suspend(client, compute, parameters=nil)

          end
        end
      end
    end
  end
end