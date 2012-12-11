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
# Description: Dummy Backend
# Author(s): Hayati Bice, Florian Feldhaus, Piotr Kasprzak
##############################################################################

require 'occi/backend/manager'
require 'hashie/hash'
require 'occi/log'
require 'uuidtools'
require 'pstore'

module OCCI
  module Backend

    # ---------------------------------------------------------------------------------------------------------------------         
    class Dummy < OCCI::Core::Resource

      attr_reader :model

      def self.kind_definition
        kind = OCCI::Core::Kind.new('http://rocci.info/server/backend#', 'dummy')

        kind.related = %w{http://rocci.org/serer#backend}
        kind.title   = "rOCCI Dummy backend"

        kind.attributes.info!.rocci!.backend!.dummy!.scheme!.Default = 'http://my.occi.service/'

        kind
      end

      def initialize(kind='http://rocci.org/server#backend', mixins=nil, attributes=nil, links=nil)
        scheme = attributes.info!.rocci!.backend!.dummy!.scheme if attributes
        scheme ||= self.class.kind_definition.attributes.info.rocci.backend.dummy.scheme.Default
        scheme.chomp!('/')
        @model = OCCI::Model.new
        @model.register_core
        @model.register_infrastructure
        @model.register_files('etc/backend/dummy/model', scheme)
        @model.register_files('etc/backend/dummy/templates', scheme)
        OCCI::Backend::Manager.register_backend(OCCI::Backend::Dummy, OCCI::Backend::Dummy::OPERATIONS)

        super(kind, mixins, attributes, links)
      end

      def authorized?(username, password)
        true
      end

      # Generate a new Dummy client for the target User, if the username
      # is nil the Client is generated for the default user
      # @param [String] username
      # @return [Client]
      def client(username='default')
        username ||= 'default'
        client = PStore.new(username)
        client.transaction do
          client['resources'] ||= []
          client['links'] ||= []
        end
        client
      end

      def get_username(cert_subject)
        cn = cert_subject [/.*\/CN=([^\/]*).*/,1]
        user = cn.downcase.gsub ' ','' if cn
        user ||= 'default'
      end

      # ---------------------------------------------------------------------------------------------------------------------
      # Operation mappings

      OPERATIONS = {}

      OPERATIONS["http://schemas.ogf.org/occi/infrastructure#compute"] = {

          # Generic resource operations
          :deploy => :compute_deploy,
          :update_state => :resource_update_state,
          :delete => :resource_delete,

          # network specific resource operations
          :start => :compute_action_start,
          :stop => :compute_action_stop,
          :restart => :compute_action_restart,
          :suspend => :compute_action_suspend
      }

      OPERATIONS["http://schemas.ogf.org/occi/infrastructure#network"] = {

          # Generic resource operations
          :deploy => :network_deploy,
          :update_state => :resource_update_state,
          :delete => :resource_delete,

          # Network specific resource operations
          :up => :network_action_up,
          :down => :network_action_down
      }

      OPERATIONS["http://schemas.ogf.org/occi/infrastructure#storage"] = {

          # Generic resource operations
          :deploy => :storage_deploy,
          :update_state => :resource_update_state,
          :delete => :resource_delete,

          # Network specific resource operations
          :online => :storage_action_online,
          :offline => :storage_action_offline,
          :backup => :storage_action_backup,
          :snapshot => :storage_action_snapshot,
          :resize => :storage_action_resize
      }

      # ---------------------------------------------------------------------------------------------------------------------
      def register_existing_resources(client)
        client.transaction(read_only=true) do
          entities = client['resources'] + client['links']
          entities.each do |entity|
            kind = @model.get_by_id(entity.kind)
            kind.entities << entity
            OCCI::Log.debug("#### Number of entities in kind #{kind.type_identifier}: #{kind.entities.size}")
          end                         
        end
      end

      # TODO: register user defined mixins

      def compute_deploy(client, compute)
        compute.id = UUIDTools::UUID.timestamp_create.to_s
        compute_action_start(client, compute)
        store(client, compute)
      end

      def storage_deploy(client, storage)
        storage.id = UUIDTools::UUID.timestamp_create.to_s
        storage_action_online(client, storage)
        store(client, storage)
      end

      def network_deploy(client, network)
        network.id = UUIDTools::UUID.timestamp_create.to_s
        network_action_up(client, network)
        store(client, network)
      end

      # ---------------------------------------------------------------------------------------------------------------------
      def store(client, resource)
        OCCI::Log.debug("### DUMMY: Deploying resource with id #{resource.id}")
        client.transaction do
          client['resources'].delete_if { |res| res.id == resource.id }
          client['resources'] << resource
        end
      end

      # ---------------------------------------------------------------------------------------------------------------------
      def resource_update_state(resource)
        OCCI::Log.debug("Updating state of resource '#{resource.attributes['occi.core.title']}'...")
      end

      # ---------------------------------------------------------------------------------------------------------------------
      def resource_delete(client, resource)
        OCCI::Log.debug("Deleting resource '#{resource.attributes['occi.core.title']}'...")
        client.transaction do
          client['resources'].delete_if { |res| res.id == resource.id }
        end
      end

      # ---------------------------------------------------------------------------------------------------------------------
      # ACTIONS
      # ---------------------------------------------------------------------------------------------------------------------

      def compute_action_start(client, compute, parameters=nil)
        action_dummy(client, compute)
        compute.attributes.occi!.compute!.state = 'active'
        compute.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#stop http://schemas.ogf.org/occi/infrastructure/compute/action#restart http://schemas.ogf.org/occi/infrastructure/compute/action#suspend|
        store(client, compute)
      end

      def compute_action_stop(client, compute, parameters=nil)
        action_dummy(client, compute)
        compute.attributes.occi!.compute!.state = 'inactive'
        compute.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
        store(client, compute)
      end

      def compute_action_restart(client, compute, parameters=nil)
        compute_action_start(client, compute)
      end

      def compute_action_suspend(client, compute, parameters=nil)
        action_dummy(client, compute)
        compute.attributes.occi!.compute!.state = 'suspended'
        compute.actions = %w|http://schemas.ogf.org/occi/infrastructure/compute/action#start|
        store(client, compute)
      end

      def storage_action_online(client, storage, parameters=nil)
        action_dummy(client, storage)
        storage.attributes.occi!.storage!.state = 'online'
        storage.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#offline http://schemas.ogf.org/occi/infrastructure/storage/action#restart http://schemas.ogf.org/occi/infrastructure/storage/action#suspend http://schemas.ogf.org/occi/infrastructure/storage/action#resize|
        store(client, storage)
      end

      def storage_action_offline(client, storage, parameters=nil)
        action_dummy(client, storage)
        storage.attributes.occi!.storage!.state = 'offline'
        storage.actions = %w|http://schemas.ogf.org/occi/infrastructure/storage/action#online http://schemas.ogf.org/occi/infrastructure/storage/action#restart http://schemas.ogf.org/occi/infrastructure/storage/action#suspend http://schemas.ogf.org/occi/infrastructure/storage/action#resize|
        store(client, storage)
      end

      def storage_action_backup(client, storage, parameters=nil)
        # nothing to do, state and actions stay the same after the backup which is instant for the dummy
      end

      def storage_action_snapshot(client, storage, parameters=nil)
        # nothing to do, state and actions stay the same after the snapshot which is instant for the dummy
      end

      def storage_action_resize(client, storage, parameters=nil)
        puts "Parameters: #{parameters}"
        storage.attributes.occi!.storage!.size = parameters[:size].to_i
        # state and actions stay the same after the resize which is instant for the dummy
        store(client, storage)
      end

      def network_action_up(client, network, parameters=nil)
        action_dummy(client, network)
        network.attributes.occi!.network!.state = 'up'
        network.actions = %w|http://schemas.ogf.org/occi/infrastructure/network/action#down|
        store(client, network)
      end

      def network_action_down(client, network, parameters=nil)
        action_dummy(client, network)
        network.attributes.occi!.network!.state = 'down'
        network.actions = %w|http://schemas.ogf.org/occi/infrastructure/network/action#up|
        store(client, network)
      end

      # ---------------------------------------------------------------------------------------------------------------------
      def action_dummy(client, resource, parameters=nil)
        OCCI::Log.debug("Calling method for resource '#{resource.attributes['occi.core.title']}' with parameters: #{parameters.inspect}")
        resource.links ||= []
        resource.links.delete_if { |link| link.rel.include? 'action' }
      end

    end

  end
end