module Backends
  module Opennebula
    class Securitygroup < Base
      include Entitylike
      include AttributesTransferable
      include MixinsAttachable
      include ErbRenderer

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
        sg = ::OpenNebula::SecurityGroup.new_with_id(identifier, raw_client)
        client(Errors::Backend::EntityStateError) { sg.info }
        securitygroup_from(sg)
      end

      # @see `Entitylike`
      def create(instance)
        valid_rules! instance['occi.securitygroup.rules']
        sg_template = security_group_from(instance)

        security_group = ::OpenNebula::SecurityGroup.new(::OpenNebula::SecurityGroup.build_xml, raw_client)
        client(Errors::Backend::EntityCreateError) { security_group.allocate(sg_template) }
        client(Errors::Backend::EntityStateError) { security_group.info }

        security_group['ID']
      end

      # @see `Entitylike`
      def delete(identifier)
        sg = ::OpenNebula::SecurityGroup.new_with_id(identifier, raw_client)
        client(Errors::Backend::EntityStateError) { sg.delete }
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
      def valid_rules!(ary)
        raise Errors::Backend::EntityStateError, 'Empty rule set is not acceptable' if ary.blank?
        ary.each do |rule|
          next if rule['protocol'].present? && rule['type'].present?
          raise Errors::Backend::EntityStateError, "Rule #{rule.inspect} is missing required elements"
        end
      end

      # :nodoc:
      def whereami
        File.expand_path(File.dirname(__FILE__))
      end
    end
  end
end
