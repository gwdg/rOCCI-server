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
# Description: OpenNebula Backend
# Author(s): Hayati Bice, Florian Feldhaus, Piotr Kasprzak
##############################################################################

require 'occi/log'
require 'erubis'

module OCCI
  module Backend
    class OpenNebula

      # ---------------------------------------------------------------------------------------------------------------------
      module Storage

        # location cache mapping OCCI locations to OpenNebula VM IDs
        @@location_cache = {}

        TEMPLATESTORAGERAWFILE = 'storage.erb'

        # ---------------------------------------------------------------------------------------------------------------------       
        #        private
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------     
        def storage_parse_backend_object(client, backend_object)

          # get information on storage object from OpenNebula backend
          backend_object.info

          storage_kind = @model.get_by_id("http://schemas.ogf.org/occi/infrastructure#storage")

          id = backend_object['TEMPLATE/OCCI_ID']
          id ||= self.generate_occi_id(storage_kind, backend_object.id.to_s)

          @@location_cache[id] = backend_object.id.to_s

          storage = OCCI::Core::Resource.new(storage_kind.type_identifier)

          storage.mixins << 'http://opennebula.org/occi/infrastructure#storage'
          backend_object.each 'TEMPLATE/OCCI_MIXIN' do |mixin|
            storage.mixins << mixin.text
          end
          storage.mixins.uniq!

          storage.id = id
          storage.title = backend_object['NAME'] if backend_object['NAME']
          storage.summary = backend_object['TEMPLATE/DESCRIPTION'] if backend_object['TEMPLATE/DESCRIPTION']

          storage.attributes.occi!.storage!.size = backend_object['TEMPLATE/SIZE'].to_f/1000 if backend_object['TEMPLATE/SIZE']

          storage.attributes.org!.opennebula!.storage!.id = backend_object['ID'] if backend_object['ID']
          storage.attributes.org!.opennebula!.storage!.type = backend_object['TEMPLATE/TYPE'] if backend_object['TEMPLATE/TYPE']
          storage.attributes.org!.opennebula!.storage!.persistent = backend_object['TEMPLATE/PERSISTENT'] if backend_object['TEMPLATE/PERSISTENT']
          storage.attributes.org!.opennebula!.storage!.dev_prefix = backend_object['TEMPLATE/DEV_PREFIX'] if backend_object['TEMPLATE/DEV_PREFIX']
          storage.attributes.org!.opennebula!.storage!.bus = backend_object['TEMPLATE/BUS'] if backend_object['TEMPLATE/BUS']
          storage.attributes.org!.opennebula!.storage!.driver = backend_object['TEMPLATE/DRIVER'] if backend_object['TEMPLATE/DRIVER']

          storage.check(@model)

          storage_set_state(backend_object, storage)

          storage_kind.entities << storage unless storage_kind.entities.select {|entity| entity.id == storage.id}.any?
        end

        # ---------------------------------------------------------------------------------------------------------------------
        public
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------
        def storage_deploy(client, storage)

          backend_object = OpenNebula::Image.new(OpenNebula::Image.build_xml, client)

          # OpenNebula requires all images to have a name/title
          storage.title ||= "Image created at " + Time.now.to_s

          template_location = File.dirname(__FILE__) + '/../../../../etc/backend/opennebula/one_templates/' + TEMPLATESTORAGERAWFILE
          template = Erubis::Eruby.new(File.read(template_location)).evaluate(:storage => storage)

          OCCI::Log.debug("Parsed template #{template}")

          # since OpenNebula 3.4 the allocate method expects a datastore, thus the arity of the allocate method is checked
          if backend_object.method(:allocate).arity == 1
            rc = backend_object.allocate(template)
          else
            rc = backend_object.allocate(template, 1)
          end
          check_rc(rc)

          backend_object.info

          storage.id ||= self.generate_occi_id(@model.get_by_id(storage.kind), backend_object['ID'].to_s)

          storage_set_state(backend_object, storage)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        def storage_set_state(backend_object, storage)
          OCCI::Log.debug("current Image state is: #{backend_object.state_str}")
          case backend_object.state_str
            when "READY", "USED", "LOCKED" then
              storage.attributes.occi!.storage!.state = "online"
              storage.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#offline http://schemas.ogf.org/occi/infrastructure/storage/action#backup http://schemas.ogf.org/occi/infrastructure/storage/action#snapshot http://schemas.ogf.org/occi/infrastructure/storage/action#resize|
            when "ERROR" then
              storage.attributes.occi!.storage!.state = "degraded"
              storage.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#online'|
            else
              storage.attributes.occi!.storage!.state = "offline"
              storage.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#online http://schemas.ogf.org/occi/infrastructure/storage/action#backup http://schemas.ogf.org/occi/infrastructure/storage/action#snapshot http://schemas.ogf.org/occi/infrastructure/storage/action#resize|
          end
        end

        # ---------------------------------------------------------------------------------------------------------------------
        def storage_delete(client, storage)
          backend_object = OpenNebula::Image.new(OpenNebula::Image.build_xml(@@location_cache[storage.id]), client)
          rc = backend_object.delete
          check_rc(rc)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        def storage_register_all_instances(client)
          occi_objects = []
          backend_object_pool=ImagePool.new(client)
          backend_object_pool.info_all
          backend_object_pool.each { |backend_object| storage_parse_backend_object(client, backend_object) }
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # STORAGE ACTIONS
        # ---------------------------------------------------------------------------------------------------------------------

        # ---------------------------------------------------------------------------------------------------------------------
        def storage_action_dummy(client, storage, parameters)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action online
        def storage_online(client, storage, parameters)
          backend_object = OpenNebula::Image.new(OpenNebula::Image.build_xml(@@location_cache[storage.id]), client)
          rc = backend_object.enable
          check_rc(rc)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action offline
        def storage_offline(client, storage, parameters)
          backend_object = OpenNebula::Image.new(OpenNebula::Image.build_xml(@@location_cache[storage.id]), client)
          rc = backend_object.disable
          check_rc(rc)
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action backup
        def storage_backup(client, storage, parameters)
          OCCI::Log.debug("not yet implemented")
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action snapshot
        def storage_snapshot(client, storage, parameters)
          OCCI::Log.debug("not yet implemented")
        end

        # ---------------------------------------------------------------------------------------------------------------------
        # Action resize
        def storage_resize(client, storage, parameters)
          OCCI::Log.debug("not yet implemented")
        end

      end
    end
  end
end
