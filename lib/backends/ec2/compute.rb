module Backends
  module Ec2
    class Compute < Backends::Ec2::Base
      COMPUTE_NINTF_REGEXP = /compute_(?<compute_id>i-[[:alnum:]]+)_nic_(?<compute_nic_id>eni-[[:alnum:]]+)/
      COMPUTE_SLINK_REGEXP = /compute_(?<compute_id>i-[[:alnum:]]+)_disk_(?<compute_disk_id>vol-[[:alnum:]]+)/

      DALLI_OS_TPL_KEY = 'ec2_os_tpls'
      IMAGE_FILTERING_POLICIES_OWNED = ['only_owned', 'owned_and_listed'].freeze
      IMAGE_FILTERING_POLICIES_LISTED = ['only_listed', 'owned_and_listed'].freeze

      # Gets all compute instance IDs, no details, no duplicates. Returned
      # identifiers must correspond to those found in the occi.core.id
      # attribute of ::Occi::Infrastructure::Compute instances.
      #
      # @example
      #    list_ids #=> []
      #    list_ids #=> ["65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf",
      #                             "ggf4f65adfadf-adgg4ad-daggad-fydd4fadyfdfd"]
      #
      # @param mixins [::Occi::Core::Mixins] a filter containing mixins
      # @return [Array<String>] IDs for all available compute instances
      # @effects Gets the status of existing AWS instances
      def list_ids(mixins = nil)
        id_list = []

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          instance_statuses = @ec2_client.describe_instance_status(include_all_instances: true).instance_statuses
          instance_statuses.each { |istatus| id_list << istatus[:instance_id] } if instance_statuses
        end

        id_list
      end

      # Gets all compute instances, instances must be filtered
      # by the specified filter, filter (if set) must contain an ::Occi::Core::Mixins instance.
      # Returned collection must contain ::Occi::Infrastructure::Compute instances
      # wrapped in ::Occi::Core::Resources.
      #
      # @example
      #    computes = list #=> #<::Occi::Core::Resources>
      #    computes.first #=> #<::Occi::Infrastructure::Compute>
      #
      #    mixins = ::Occi::Core::Mixins.new << ::Occi::Core::Mixin.new
      #    computes = list(mixins) #=> #<::Occi::Core::Resources>
      #
      # @param mixins [::Occi::Core::Mixins] a filter containing mixins
      # @return [::Occi::Core::Resources] a collection of compute instances
      # @effects Gets the status of existing AWS instances
      def list(mixins = nil)
        computes = ::Occi::Core::Resources.new

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          rsrvts = @ec2_client.describe_instances.reservations
          rsrvts.each do |reservation|
            next unless reservation && reservation.instances
            reservation.instances.each { |instance| computes << parse_backend_obj(instance, reservation[:reservation_id]) }
          end if rsrvts
        end

        computes
      end

      # Gets a specific compute instance as ::Occi::Infrastructure::Compute.
      # ID given as an argument must match the occi.core.id attribute inside
      # the returned ::Occi::Infrastructure::Compute instance, however it is possible
      # to implement internal mapping to a platform-specific identifier.
      #
      # @example
      #    compute = get('65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf')
      #        #=> #<::Occi::Infrastructure::Compute>
      #
      # @param compute_id [String] OCCI identifier of the requested compute instance
      # @return [::Occi::Infrastructure::Compute, nil] a compute instance or `nil`
      # @effects Gets the status of a existing AWS instance
      def get(compute_id)
        filters = []
        filters << { name: 'instance-id', values: [compute_id] }

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          rsrvts = @ec2_client.describe_instances(filters: filters).reservations
          rsrvt = rsrvts ? rsrvts.first : nil
          return nil unless rsrvt && rsrvt.instances && rsrvt.instances.first

          parse_backend_obj(rsrvt.instances.first, rsrvt[:reservation_id])
        end
      end

      # Instantiates a new compute instance from ::Occi::Infrastructure::Compute.
      # ID given in the occi.core.id attribute is optional and can be changed
      # inside this method. Final occi.core.id must be returned as a String.
      # If the requested instance cannot be created, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute = ::Occi::Infrastructure::Compute.new
      #    compute_id = create(compute)
      #        #=> "65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf"
      #
      # @param compute [::Occi::Infrastructure::Compute] compute instance containing necessary attributes
      # @return [String] final identifier of the new compute instance
      # @effects Launches an instance
      # @effects Creates tags for it
      # @effects Attaches storage
      # @effects Attaches network interfaces
      def create(compute)
        compute_id = compute.id

        os_tpl_mixins = compute.mixins.get_related_to(::Occi::Infrastructure::OsTpl.mixin.type_identifier)
        if os_tpl_mixins.empty?
          fail Backends::Errors::ResourceNotValidError,
               "Given instance does not contain an os_tpl " \
               "mixin necessary to create a virtual machine!"
        else
          compute_id = create_with_os_tpl(compute)
        end

        compute_id
      end

      # Deletes all compute instances, instances to be deleted must be filtered
      # by the specified filter, filter (if set) must contain an ::Occi::Core::Mixins instance.
      # If the requested instances cannot be deleted, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    delete_all #=> true
      #
      #    mixins = ::Occi::Core::Mixins.new << ::Occi::Core::Mixin.new
      #    delete_all(mixins)  #=> true
      #
      # @param mixins [::Occi::Core::Mixins] a filter containing mixins
      # @return [true, false] result of the operation
      # @effects Disassociates and releases elastic IP addresses
      # @effects Shuts down multiple AWS instances
      def delete_all(mixins = nil)
        all_ids = list_ids(mixins)
        delete_release_public(all_ids)

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          @ec2_client.terminate_instances(instance_ids: all_ids)
        end unless all_ids.blank?

        true
      end

      # Deletes a specific compute instance, instance to be deleted is
      # specified by an ID, this ID must match the occi.core.id attribute
      # of the deleted instance.
      # If the requested instance cannot be deleted, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    delete("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf") #=> true
      #
      # @param compute_id [String] an identifier of a compute instance to be deleted
      # @return [true, false] result of the operation
      # @effects Shuts down the given AWS instance
      # @effects Disassociates and releases elastic IP address assigned to the given instance
      def delete(compute_id)
        delete_release_public([compute_id])

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          @ec2_client.terminate_instances(instance_ids: [compute_id])
        end

        true
      end

      # Partially updates an existing compute instance, instance to be updated
      # is specified by compute_id.
      # If the requested instance cannot be updated, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    attributes = ::Occi::Core::Attributes.new
      #    mixins = ::Occi::Core::Mixins.new
      #    links = ::Occi::Core::Links.new
      #    partial_update(compute_id, attributes, mixins, links) #=> true
      #
      # @param compute_id [String] unique identifier of a compute instance to be updated
      # @param attributes [::Occi::Core::Attributes] a collection of attributes to be updated
      # @param mixins [::Occi::Core::Mixins] a collection of mixins to be added
      # @param links [::Occi::Core::Links] a collection of links to be added
      # @return [true, false] result of the operation
      # @todo Method not yet implemented
      def partial_update(compute_id, attributes = nil, mixins = nil, links = nil)
        # TODO: impl, do not forget the effects tag
        fail Backends::Errors::MethodNotImplementedError, 'Not Implemented!'
      end

      # Updates an existing compute instance, instance to be updated is specified
      # using the occi.core.id attribute of the instance passed as an argument.
      # If the requested instance cannot be updated, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    compute = ::Occi::Infrastructure::Compute.new
      #    update(compute) #=> true
      #
      # @param compute [::Occi::Infrastructure::Compute] instance containing updated information
      # @return [true, false] result of the operation
      # @todo Method not yet implemented
      def update(compute)
        # TODO: impl, do not forget the effects tag
        fail Backends::Errors::MethodNotImplementedError, 'Not Implemented!'
      end

      # Attaches a network to an existing compute instance, compute instance and network
      # instance in question are identified by occi.core.source, occi.core.target attributes.
      # If the requested instance cannot be linked, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    networkinterface = ::Occi::Infrastructure::Networkinterface.new
      #    attach_network(networkinterface) #=> "65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf"
      #
      # @param networkinterface [::Occi::Infrastructure::Networkinterface] NI instance containing necessary attributes
      # @return [String] final identifier of the new network interface
      # @effects Allocates elastic IP address
      # @effects Associates the allocated address
      def attach_network(networkinterface)
        fail Backends::Errors::ResourceNotValidError, 'Attributes source and target are required!' \
          if networkinterface.target.blank? || networkinterface.source.blank?
        network_id = networkinterface.target.kind_of?(::Occi::Core::Resource) ? networkinterface.target.id : networkinterface.target.split('/').last
        source_id = networkinterface.source.kind_of?(::Occi::Core::Resource) ? networkinterface.source.id : networkinterface.source.split('/').last
        fail Backends::Errors::ResourceNotValidError, 'Attributes source and target are required!' \
          if network_id.blank? || source_id.blank?

        case network_id
        when 'public'
          # attaching a floating public IP address
          attach_network_public(networkinterface)
        when 'private'
          # attaching a floating private IP address
          attach_network_private(networkinterface)
        else
          # attaching a VPC
          attach_network_vpc(networkinterface)
        end
      end

      # Attaches a storage to an existing compute instance, compute instance and storage
      # instance in question are identified by occi.core.source, occi.core.target attributes.
      # If the requested instance cannot be linked, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    storagelink = ::Occi::Infrastructure::Storagelink.new
      #    attach_storage(storagelink) #=> "65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf"
      #
      # @param storagelink [::Occi::Infrastructure::Storagelink] SL instance containing necessary attributes
      # @return [String] final identifier of the new storage link
      # @effects Attaches an existing volume to a running instance
      def attach_storage(storagelink)
        fail Backends::Errors::ResourceNotValidError, 'Attributes source and target are required!' \
          if storagelink.target.blank? || storagelink.source.blank?
        target_id = storagelink.target.kind_of?(::Occi::Core::Resource) ? storagelink.target.id : storagelink.target.split('/').last
        source_id = storagelink.source.kind_of?(::Occi::Core::Resource) ? storagelink.source.id : storagelink.source.split('/').last
        fail Backends::Errors::ResourceNotValidError, 'Attributes source and target are required!' \
          if target_id.blank? || source_id.blank?

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          @ec2_client.attach_volume(
            volume_id: target_id,
            instance_id: source_id,
            device: storagelink.attributes.occi!.storagelink!.deviceid || '/dev/xvdf',
          )
        end

        "compute_#{source_id}_disk_#{target_id}"
      end

      # Detaches a network from an existing compute instance, the compute instance in question
      # must be identifiable using the networkinterface ID passed as an argument.
      # If the requested link instance cannot be detached, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    detach_network("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf") #=> true
      #
      # @param networkinterface_id [String] network interface identifier
      # @return [true, false] result of the operation
      # @effects Dissasociates an elastic IP address
      # @effects Releases an elastic IP address
      def detach_network(networkinterface_id)
        networkinterface = get_network(networkinterface_id)
        network_id = networkinterface.attributes['occi.core.target'].split('/').last

        case network_id
        when 'public'
          # detaching a floating public IP address
          detach_network_public(networkinterface)
        when 'private'
          # detaching a floating private IP address
          detach_network_private(networkinterface)
        else
          # detaching a VPC
          detach_network_vpc(networkinterface)
        end

        true
      end

      # Detaches a storage from an existing compute instance, the compute instance in question
      # must be identifiable using the storagelink ID passed as an argument.
      # If the requested link instance cannot be detached, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    detach_storage("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf") #=> true
      #
      # @param storagelink_id [String] storage link identifier
      # @return [true, false] result of the operation
      # @effects Detaches a volume from a running instance
      def detach_storage(storagelink_id)
        matched = COMPUTE_SLINK_REGEXP.match(storagelink_id)
        fail Backends::Errors::IdentifierNotValidError, 'ID of the given storagelink is not valid!' unless matched

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          @ec2_client.detach_volume(
            volume_id: matched[:compute_disk_id],
            instance_id: matched[:compute_id],
            force: true,
          )
        end

        true
      end

      # Gets a network from an existing compute instance, the compute instance in question
      # must be identifiable using the networkinterface ID passed as an argument.
      # If the requested link instance cannot be found, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    get_network("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf")
      #        #=> #<::Occi::Infrastructure::Networkinterface>
      #
      # @param networkinterface_id [String] network interface identifier
      # @return [::Occi::Infrastructure::Networkinterface] instance of the found networkinterface
      # @effects Gets the status of an existing instance
      def get_network(networkinterface_id)
        matched = COMPUTE_NINTF_REGEXP.match(networkinterface_id)
        fail Backends::Errors::IdentifierNotValidError, 'ID of the given networkinterface is not valid!' unless matched

        compute = get(matched[:compute_id]) || ::Occi::Infrastructure::Compute.new
        intf = compute.links.to_a.select { |l| l.id == networkinterface_id }
        fail Backends::Errors::ResourceNotFoundError, 'Networkinterface with the given ID does not exist!' if intf.blank?

        intf.first
      end

      # Gets a storage from an existing compute instance, the compute instance in question
      # must be identifiable using the storagelink ID passed as an argument.
      # If the requested link instance cannot be detached, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    get_storage("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf")
      #        #=> #<::Occi::Infrastructure::Storagelink>
      #
      # @param storagelink_id [String] storage link identifier
      # @return [::Occi::Infrastructure::Storagelink] instance of the found storagelink
      # @effects Gets the status of an existing instance
      def get_storage(storagelink_id)
        matched = COMPUTE_SLINK_REGEXP.match(storagelink_id)
        fail Backends::Errors::IdentifierNotValidError, 'ID of the given storagelink is not valid!' unless matched

        compute = get(matched[:compute_id]) || ::Occi::Infrastructure::Compute.new
        link = compute.links.to_a.select { |l| l.id == storagelink_id }
        fail Backends::Errors::ResourceNotFoundError, 'Storagelink with the given ID does not exist!' if link.blank?

        link.first
      end

      # Triggers an action on all existing compute instances, instances must be filtered
      # by the specified filter, filter (if set) must contain an ::Occi::Core::Mixins instance,
      # action is identified by the action.term attribute of the action instance passed as an argument.
      # If the requested action cannot be triggered, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    action_instance = ::Occi::Core::ActionInstance.new
      #    mixins = ::Occi::Core::Mixins.new << ::Occi::Core::Mixin.new
      #    trigger_action_on_all(action_instance, mixin) #=> true
      #
      # @param action_instance [::Occi::Core::ActionInstance] action to be triggered
      # @param mixins [::Occi::Core::Mixins] a filter containing mixins
      # @return [true, false] result of the operation
      # @effects Makes all instances start, restart or stop
      def trigger_action_on_all(action_instance, mixins = nil)
        list_ids(mixins).each { |cmpt| trigger_action(cmpt, action_instance) }
        true
      end

      # Triggers an action on an existing compute instance, the compute instance in question
      # is identified by a compute instance ID, action is identified by the action.term attribute
      # of the action instance passed as an argument.
      # If the requested action cannot be triggered, an error describing the
      # problem must be raised, @see Backends::Errors.
      #
      # @example
      #    action_instance = ::Occi::Core::ActionInstance.new
      #    trigger_action("65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf", action_instance)
      #      #=> true
      #
      # @param compute_id [String] compute instance identifier
      # @param action_instance [::Occi::Core::ActionInstance] action to be triggered
      # @return [true, false] result of the operation
      # @effects Makes an instance start, restart or stop
      def trigger_action(compute_id, action_instance)
        case action_instance.action.type_identifier
        when 'http://schemas.ogf.org/occi/infrastructure/compute/action#stop'
          trigger_action_stop(compute_id, action_instance.attributes)
        when 'http://schemas.ogf.org/occi/infrastructure/compute/action#start'
          trigger_action_start(compute_id, action_instance.attributes)
        when 'http://schemas.ogf.org/occi/infrastructure/compute/action#restart'
          trigger_action_restart(compute_id, action_instance.attributes)
        else
          fail Backends::Errors::ActionNotImplementedError,
               "Action #{action_instance.action.type_identifier.inspect} is not implemented!"
        end

        true
      end

      # Returns a collection of custom mixins introduced (and specific for)
      # the enabled backend. Only mixins and actions are allowed.
      #
      # @return [::Occi::Collection] collection of extensions (custom mixins and/or actions)
      def get_extensions
        read_extensions 'compute', @options.model_extensions_dir
      end

      # Gets backend-specific `os_tpl` mixins which should be merged
      # into ::Occi::Model of the server.
      #
      # @example
      #    mixins = list_os_tpl #=> #<::Occi::Core::Mixins>
      #    mixins.first #=> #<::Occi::Core::Mixin>
      #
      # @return [::Occi::Core::Mixins] a collection of mixins
      # @effects Gets status of machine images
      def list_os_tpl
        filters = []
        filters << { name: 'image-type', values: ['machine'] }
        filters << { name: 'image-id', values: @image_filtering_image_list } if IMAGE_FILTERING_POLICIES_LISTED.include?(@image_filtering_policy)
        owners = IMAGE_FILTERING_POLICIES_OWNED.include?(@image_filtering_policy) ? [ 'self' ] : nil

        ec2_images_ary = Backends::Helpers::CachingHelper.load(@dalli_cache, DALLI_OS_TPL_KEY)
        unless ec2_images_ary
          ec2_images_ary = []

          Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
            ec2_images = if owners
                           @ec2_client.describe_images(filters: filters, owners: owners).images
                         else
                           @ec2_client.describe_images(filters: filters).images
                         end

            ec2_images.each { |ec2_image| ec2_images_ary << { image_id: ec2_image[:image_id], name: ec2_image[:name] } } if ec2_images
          end

          Backends::Helpers::CachingHelper.save(@dalli_cache, DALLI_OS_TPL_KEY, ec2_images_ary)
        end

        os_tpls = ::Occi::Core::Mixins.new
        ec2_images_ary.each { |ec2_image| os_tpls << mixin_from_image(ec2_image) }

        os_tpls
      end

      # Gets a specific os_tpl mixin instance as ::Occi::Core::Mixin.
      # Term given as an argument must match the term inside
      # the returned ::Occi::Core::Mixin instance.
      #
      # @example
      #    os_tpl = get_os_tpl('65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf')
      #        #=> #<::Occi::Core::Mixin>
      #
      # @param term [String] OCCI term of the requested os_tpl mixin instance
      # @return [::Occi::Core::Mixin, nil] a mixin instance or `nil`
      # @effects Gets status of a given machine image
      def get_os_tpl(term)
        filters = []
        filters << { name: 'image-type', values: ['machine'] }
        filters << { name: 'image-id', values: [term] }

        Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
          ec2_images = @ec2_client.describe_images(filters: filters).images
          (ec2_images && ec2_images.first) ? mixin_from_image(ec2_images.first) : nil
        end
      end

      # Gets platform- or backend-specific `resource_tpl` mixins which should be merged
      # into ::Occi::Model of the server.
      #
      # @example
      #    mixins = list_resource_tpl #=> #<::Occi::Core::Mixins>
      #    mixins.first  #=> #<::Occi::Core::Mixin>
      #
      # @return [::Occi::Core::Mixins] a collection of mixins
      # @effects <i>none</i>: call answered from within the backend
      def list_resource_tpl
        @resource_tpl
      end

      # Gets a specific resource_tpl mixin instance as ::Occi::Core::Mixin.
      # Term given as an argument must match the term inside
      # the returned ::Occi::Core::Mixin instance.
      #
      # @example
      #    resource_tpl = get_resource_tpl('65d4f65adfadf-ad2f4ad-daf5ad-f5ad4fad4ffdf')
      #        #=> #<::Occi::Core::Mixin>
      #
      # @param term [String] OCCI term of the requested resource_tpl mixin instance
      # @return [::Occi::Core::Mixin, nil] a mixin instance or `nil`
      # @effects <i>none</i>: call answered from within the backend
      def get_resource_tpl(term)
        list_resource_tpl.to_a.select { |m| m.term == term }.first
      end

      private

      #
      #
      def image_to_term(ec2_image)
        ec2_image[:image_id]
      end

      #
      #
      def term_to_image_id(term)
        term
      end

      #
      #
      def mixin_from_image(ec2_image)
        depends = %w|http://schemas.ogf.org/occi/infrastructure#os_tpl|
        term = image_to_term(ec2_image)
        scheme = "#{@options.backend_scheme}/occi/infrastructure/os_tpl#"
        title = ec2_image[:name] || 'unknown'
        location = "/mixin/os_tpl/#{term}/"
        applies = %w|http://schemas.ogf.org/occi/infrastructure#compute|

        ::Occi::Core::Mixin.new(scheme, term, title, nil, depends, nil, location, applies)
      end

      #
      #
      def itype_to_term(ec2_itype)
        ec2_itype ? ec2_itype.gsub('.', '_') : nil
      end

      #
      #
      def term_to_itype(term)
        term ? term.gsub('_', '.') : nil
      end

      # Load methods called from list/get
      include Backends::Ec2::Helpers::ComputeParseHelper

      # Load methods called from create
      include Backends::Ec2::Helpers::ComputeCreateHelper

      # Load methods called from trigger_action
      include Backends::Ec2::Helpers::ComputeActionHelper

      # Load methods called from (at|de)tach_network
      include Backends::Ec2::Helpers::ComputeNetworkHelper

      # Load methods called from delete
      include Backends::Ec2::Helpers::ComputeDeleteHelper
    end
  end
end
