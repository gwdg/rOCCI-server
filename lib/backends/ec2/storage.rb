module Backends
  module Ec2
    module Storage
      # Gets all storage instance IDs, no details, no duplicates. Returned
      # identifiers must correspond to those found in the occi.core.id
      # attribute of Occi::Infrastructure::Storage instances.
      #
      # @example
      #    storage_list_ids #=> []
      #    storage_list_ids #=> ["65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf",
      #                             "ggf4f65adfadf-adgg4ad-daggad-fydd4fadyfdfd"]
      #
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [Array<String>] IDs for all available storage instances
      # @effects Gets status of volumes
      def storage_list_ids(mixins = nil)
        id_list = []

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          volume_statuses = @ec2_client.describe_volume_status.volume_statuses
          volume_statuses.each { |vstatus| id_list << vstatus[:volume_id] } if volume_statuses
        end

        id_list
      end

      # Gets all storage instances, instances must be filtered
      # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance.
      # Returned collection must contain Occi::Infrastructure::Storage instances
      # wrapped in Occi::Core::Resources.
      #
      # @example
      #    storages = storage_list #=> #<Occi::Core::Resources>
      #    storages.first #=> #<Occi::Infrastructure::Storage>
      #
      #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
      #    storages = storage_list(mixins) #=> #<Occi::Core::Resources>
      #
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [Occi::Core::Resources] a collection of storage instances
      # @effects Gets status of volumes
      def storage_list(mixins = nil)
        storages = Occi::Core::Resources.new

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          volumes = @ec2_client.describe_volumes.volumes
          volumes.each do |volume|
            next unless volume
            storages << storage_parse_backend_obj(volume)
          end if volumes
        end

        storages
      end

      # Gets a specific storage instance as Occi::Infrastructure::Storage.
      # ID given as an argument must match the occi.core.id attribute inside
      # the returned Occi::Infrastructure::Storage instance, however it is possible
      # to implement internal mapping to a platform-specific identifier.
      #
      # @example
      #    storage = storage_get('65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf')
      #        #=> #<Occi::Infrastructure::Storage>
      #
      # @param storage_id [String] OCCI identifier of the requested storage instance
      # @return [Occi::Infrastructure::Storage, nil] a storage instance or `nil`
      # @effects Gets status of volumes
      def storage_get(storage_id)
        filters = []
        filters << { name: 'volume-id', values: [storage_id] }

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          volumes = @ec2_client.describe_volumes(filters: filters).volumes
          volume = volumes ? volumes.first : nil
          return nil unless volume

          storage_parse_backend_obj(volume)
        end
      end

      # Instantiates a new storage instance from Occi::Infrastructure::Storage.
      # ID given in the occi.core.id attribute is optional and can be changed
      # inside this method. Final occi.core.id must be returned as a String.
      # If the requested instance cannot be created, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    storage = Occi::Infrastructure::Storage.new
      #    storage_id = storage_create(storage)
      #        #=> "65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf"
      #
      # @param storage [Occi::Infrastructure::Storage] storage instance containing necessary attributes
      # @return [String] final identifier of the new storage instance
      # @effects Initializes a volume
      # @effects Creates tags for the volume
      def storage_create(storage)
        tags = []
        tags << { key: 'Name', value: (storage.title || "rOCCI-server volume #{storage.size || 1}GB") }

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          volume = @ec2_client.create_volume(
            size: storage.size || 1,
            availability_zone: @options.aws_availability_zone,
            volume_type: "standard"
          )

          @ec2_client.create_tags(
            resources: [volume[:volume_id]],
            tags: tags
          )

          volume[:volume_id]
        end
      end

      # Deletes all storage instances, instances to be deleted must be filtered
      # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance.
      # If the requested instances cannot be deleted, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    storage_delete_all #=> true
      #
      #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
      #    storage_delete_all(mixins)  #=> true
      #
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [true, false] result of the operation
      # @effects Deletes volumes
      def storage_delete_all(mixins = nil)
        volume_ids = storage_list_ids(mixins)
        volume_ids.each { |volume_id| storage_delete(volume_id) }

        true
      end

      # Deletes a specific storage instance, instance to be deleted is
      # specified by an ID, this ID must match the occi.core.id attribute
      # of the deleted instance.
      # If the requested instance cannot be deleted, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    storage_delete("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf") #=> true
      #
      # @param storage_id [String] an identifier of a storage instance to be deleted
      # @return [true, false] result of the operation
      # @effects Deletes a volume
      def storage_delete(storage_id)
        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          @ec2_client.delete_volume(volume_id: storage_id)
        end

        true
      end

      # Partially updates an existing storage instance, instance to be updated
      # is specified by storage_id.
      # If the requested instance cannot be updated, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    attributes = Occi::Core::Attributes.new
      #    mixins = Occi::Core::Mixins.new
      #    links = Occi::Core::Links.new
      #    storage_partial_update(storage_id, attributes, mixins, links) #=> true
      #
      # @param storage_id [String] unique identifier of a storage instance to be updated
      # @param attributes [Occi::Core::Attributes] a collection of attributes to be updated
      # @param mixins [Occi::Core::Mixins] a collection of mixins to be added
      # @param links [Occi::Core::Links] a collection of links to be added
      # @return [true, false] result of the operation
      # @todo Method not yet implemented
      def storage_partial_update(storage_id, attributes = nil, mixins = nil, links = nil)
        # TODO: impl
        fail Backends::Errors::MethodNotImplementedError, 'Partial updates are currently not supported!'
      end

      # Updates an existing storage instance, instance to be updated is specified
      # using the occi.core.id attribute of the instance passed as an argument.
      # If the requested instance cannot be updated, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    storage = Occi::Infrastructure::Storage.new
      #    storage_update(storage) #=> true
      #
      # @param storage [Occi::Infrastructure::Storage] instance containing updated information
      # @return [true, false] result of the operation
      # @todo Method not implemented
      def storage_update(storage)
        fail Backends::Errors::MethodNotImplementedError, 'Not Implemented!'
      end

      # Triggers an action on all existing storage instance, instances must be filtered
      # by the specified filter, filter (if set) must contain an Occi::Core::Mixins instance,
      # action is identified by the action.term attribute of the action instance passed as an argument.
      # If the requested action cannot be triggered, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    action_instance = Occi::Core::ActionInstance.new
      #    mixins = Occi::Core::Mixins.new << Occi::Core::Mixin.new
      #    storage_trigger_action_on_all(action_instance, mixin) #=> true
      #
      # @param action_instance [Occi::Core::ActionInstance] action to be triggered
      # @param mixins [Occi::Core::Mixins] a filter containing mixins
      # @return [true, false] result of the operation
      # @effects For action <i>snapshot</i>: Creates a snapshot of the given volume
      # @effects <i>no effect</i> for other actions (not implemented)
      def storage_trigger_action_on_all(action_instance, mixins = nil)
        storage_list_ids(mixins).each { |strg| storage_trigger_action(strg, action_instance) }
        true
      end

      # Triggers an action on an existing storage instance, the storage instance in question
      # is identified by a storage instance ID, action is identified by the action.term attribute
      # of the action instance passed as an argument.
      # If the requested action cannot be triggered, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    action_instance = Occi::Core::ActionInstance.new
      #    storage_trigger_action("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf", action_instance)
      #      #=> true
      #
      # @param storage_id [String] storage instance identifier
      # @param action_instance [Occi::Core::ActionInstance] action to be triggered
      # @return [true, false] result of the operation
      # @effects For action <i>snapshot</i>: Creates a snapshot of the given volume
      # @effects <i>no effect</i> for other actions (not implemented)
      def storage_trigger_action(storage_id, action_instance)
        case action_instance.action.type_identifier
        when 'http://schemas.ogf.org/occi/infrastructure/storage/action#snapshot'
          storage_trigger_action_snapshot(storage_id, action_instance.attributes)
        else
          fail Backends::Errors::ActionNotImplementedError,
               "Action #{action_instance.action.type_identifier.inspect} is not implemented!"
        end

        true
      end

      private

      # Load methods called from storage_list/storage_get
      include Backends::Ec2::Helpers::StorageParseHelper

      # Load methods called from storage_trigger_action
      include Backends::Ec2::Helpers::StorageActionHelper
    end
  end
end
