require 'backends/opennebula/base'

module Backends
  module Opennebula
    class Securitygroup < Base
      include Backends::Helpers::Entitylike
      include Backends::Helpers::AttributesTransferable
      include Backends::Helpers::MixinsAttachable
      include Backends::Helpers::ErbRenderer

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::InfrastructureExt::SecurityGroup
        end

        # :nodoc:
        def entity_identifier
          Occi::InfrastructureExt::Constants::SECURITY_GROUP_KIND
        end
      end

      # @see `Entitylike`
      def identifiers(_filter = Set.new)
        Set.new(pool(:security_group, :info_all).map { |sg| sg['ID'] })
      end

      # @see `Entitylike`
      def list(_filter = Set.new)
        coll = Occi::Core::Collection.new
        pool(:security_group, :info_all).each { |sg| coll << securitygroup_from(sg) }
        coll
      end

      # @see `Entitylike`
      def instance(identifier)
        securitygroup_from pool_element(:security_group, identifier, :info)
      end

      # @see `Entitylike`
      def create(instance)
        pool_element_allocate(:security_group, security_group_from(instance))['ID']
      end

      # @see `Entitylike`
      def delete(identifier)
        sg = pool_element(:security_group, identifier)
        client(Errors::Backend::EntityActionError) { sg.delete }
      end

      private

      # Converts a ONe security group instance to a valid securitygroup instance.
      #
      # @param security_group [OpenNebula::SecurityGroup] instance to transform
      # @return [Occi::InfrastructureExt::SecurityGroup] transformed instance
      def securitygroup_from(security_group)
        sg = instance_builder.get(self.class.entity_identifier)

        attach_mixins! security_group, sg
        transfer_attributes! security_group, sg, Constants::Securitygroup::TRANSFERABLE_ATTRIBUTES

        sg
      end

      # Converts an OCCI securitygroup instance to a valid ONe security group template.
      #
      # @param storage [Occi::InfrastructureExt::SecurityGroup] instance to transform
      # @return [String] ONe template
      def security_group_from(securitygroup)
        template_path = File.join(template_directory, 'securitygroup.erb')
        data = { instance: securitygroup, identity: active_identity }
        erb_render template_path, data
      end

      # :nodoc:
      def attach_mixins!(_security_group, sg)
        sg << server_model.find_regions.first
        server_model.find_availability_zones.each { |az| sg << az }
      end

      # :nodoc:
      def whereami
        File.expand_path(File.dirname(__FILE__))
      end
    end
  end
end
