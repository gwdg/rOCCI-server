module Backends
  module Opennebula
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
      def storage_list_ids(mixins = nil)
        # TODO: impl filtering with mixins
        backend_image_pool = ::OpenNebula::ImagePool.new(@client)
        rc = backend_image_pool.info_all
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        storage = []
        backend_image_pool.each do |backend_image|
          storage << backend_image['ID']
        end

        storage
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
      def storage_list(mixins = nil)
        # TODO: impl filtering with mixins
        storage = Occi::Core::Resources.new
        backend_storage_pool = ::OpenNebula::ImagePool.new(@client)
        rc = backend_storage_pool.info_all
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        backend_storage_pool.each do |backend_storage|
          storage << storage_parse_backend_obj(backend_storage)
        end

        storage
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
      def storage_get(storage_id)
        image = ::OpenNebula::Image.new(::OpenNebula::Image.build_xml(storage_id), @client)
        rc = image.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        storage_parse_backend_obj(image)
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
      def storage_create(storage)
        @logger.debug "[Backends] [OpennebulaBackend] Creating storage #{storage.inspect} "\
                      "in DS[#{@options.storage_datastore_id}]"

        # include some basic mixins
        # WARNING: adding mix-ins will re-set their attributes
        attr_backup = Occi::Core::Attributes.new(storage.attributes)
        storage.mixins << 'http://opennebula.org/occi/infrastructure#storage'
        storage.attributes = attr_backup

        template_location = File.join(@options.templates_dir, 'storage.erb')
        template = Erubis::Eruby.new(File.read(template_location)).evaluate(storage: storage)

        @logger.debug "[Backends] [OpennebulaBackend] Template #{template.inspect}"

        image_alloc = ::OpenNebula::Image.build_xml
        backend_object = ::OpenNebula::Image.new(image_alloc, @client)

        rc = backend_object.allocate(template, @options.storage_datastore_id.to_i)
        check_retval(rc, Backends::Errors::ResourceCreationError)

        rc = backend_object.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        rc = backend_object.persistent
        check_retval(rc, Backends::Errors::ResourceActionError)

        backend_object['ID']
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
      def storage_delete_all(mixins = nil)
        # TODO: impl filtering with mixins
        backend_storage_pool = ::OpenNebula::ImagePool.new(@client)
        rc = backend_storage_pool.info_all
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        backend_storage_pool.each do |backend_storage|
          rc = backend_storage.delete
          check_retval(rc, Backends::Errors::ResourceActionError)
        end

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
      def storage_delete(storage_id)
        storage = ::OpenNebula::Image.new(::OpenNebula::Image.build_xml(storage_id), @client)
        rc = storage.info
        check_retval(rc, Backends::Errors::ResourceRetrievalError)

        rc = storage.delete
        check_retval(rc, Backends::Errors::ResourceActionError)

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
      def storage_update(storage)
        # TODO: impl
        fail Backends::Errors::MethodNotImplementedError, 'Updates are currently not supported!'
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
      def storage_trigger_action(storage_id, action_instance)
        case action_instance.action.type_identifier
        when 'http://schemas.ogf.org/occi/infrastructure/storage/action#online'
          storage_trigger_action_online(storage_id, action_instance.attributes)
        when 'http://schemas.ogf.org/occi/infrastructure/storage/action#offline'
          storage_trigger_action_offline(storage_id, action_instance.attributes)
        when 'http://schemas.ogf.org/occi/infrastructure/storage/action#backup'
          storage_trigger_action_backup(storage_id, action_instance.attributes)
        else
          fail Backends::Errors::ActionNotImplementedError,
               "Action #{action_instance.action.type_identifier.inspect} is not implemented!"
        end

        true
      end

      private

      # Load methods called from storage_list/storage_get
      include Backends::Opennebula::Helpers::StorageParseHelper

      # Load methods called from storage_trigger_action*
      include Backends::Opennebula::Helpers::StorageActionHelper
    end
  end
end
