require 'backends/opennebula/base'

module Backends
  module Opennebula
    class ModelExtender < Base
      include Backends::Helpers::Extenderlike

      # Stuff to load into model
      EXTENSIONS = %i[regions availability_zones resource_tpls os_tpls floatingippools].freeze

      # Adjustable schema prefix
      EXCHANGEABLE_NAMESPACE = 'http://schemas.localhost/'.freeze

      # Stuff to read from VM templates
      OS_TPL_ATTRS = {
        'eu.egi.fedcloud.appliance.appdb.id' => 'TEMPLATE/CLOUDKEEPER_APPLIANCE_ID',
        'eu.egi.fedcloud.appliance.appdb.description' => 'TEMPLATE/CLOUDKEEPER_APPLIANCE_DESCRIPTION',
        'eu.egi.fedcloud.appliance.appdb.operating_system' => 'TEMPLATE/CLOUDKEEPER_APPLIANCE_OPERATING_SYSTEM',
        'eu.egi.fedcloud.appliance.appdb.version' => 'TEMPLATE/CLOUDKEEPER_APPLIANCE_VERSION',
        'eu.egi.fedcloud.appliance.appdb.mpuri' => 'TEMPLATE/CLOUDKEEPER_APPLIANCE_MPURI',
        'eu.egi.fedcloud.appliance.appdb.base_mpuri' => 'TEMPLATE/CLOUDKEEPER_APPLIANCE_BASE_MPURI',
        'eu.egi.fedcloud.appliance.appdb.image_list.id' => 'TEMPLATE/CLOUDKEEPER_APPLIANCE_IMAGE_LIST_ID'
      }.freeze

      # Stuff to load from ONe Docs
      RES_TPL_CONTENT = %i[term schema title].freeze
      RES_TPL_ATTRS = %w[
        occi.compute.cores occi.compute.memory occi.compute.architecture
        occi.compute.ephemeral_storage.size occi.compute.speed
        eu.egi.fedcloud.compute.gpu.count eu.egi.fedcloud.compute.gpu.vendor
        eu.egi.fedcloud.compute.gpu.class eu.egi.fedcloud.compute.gpu.device
      ].freeze
      ALLOWED_UNAMES = %w[oneadmin].freeze

      # @see `Extenderlike`
      def populate!(model)
        load_from_warehouse! model
        EXTENSIONS.each { |ext| send(:replace!, model, ext) }
        change_default_connectivity! model
        model
      end

      private

      # :nodoc:
      def load_from_warehouse!(model)
        Warehouse.bootstrap! model
      end

      # :nodoc:
      def replace!(model, type)
        skeleton = model.send("find_#{type}").first
        raise Errors::Backend::InternalError, 'Failed to get mixin skeleton from warehouse' unless skeleton
        model.remove skeleton

        send("add_#{type}!", model, skeleton)
      end

      # :nodoc:
      def add_regions!(model, skeleton)
        r = skeleton.clone
        r.schema = change_namespace(r.schema)
        model << r
      end

      # :nodoc:
      def add_availability_zones!(model, skeleton)
        pool(:cluster).each do |cluster|
          az = skeleton.clone

          az.term = cluster['ID']
          az.title = cluster['NAME']
          az.schema = change_namespace(az.schema)
          az.location = URI.parse("/mixin/availability_zone/#{cluster['ID']}")

          model << az
        end
      end

      # :nodoc:
      def add_os_tpls!(model, skeleton)
        pool(:template, :info_group).each do |template|
          os = skeleton.clone
          os.attributes = deep_copy(os.attributes)
          change_os_tpl! os, template
          clean_unused! os.attributes

          model << os
        end
      end

      # :nodoc:
      def change_os_tpl!(os, template)
        os.term = template['ID']
        os.title = template['TEMPLATE/CLOUDKEEPER_APPLIANCE_TITLE'] || template['NAME']
        os.schema = change_namespace(os.schema)
        os.location = URI.parse("/mixin/os_tpl/#{template['ID']}")
        OS_TPL_ATTRS.each_pair { |k, v| os[k] = template[v] }
      end

      # :nodoc:
      def add_resource_tpls!(model, skeleton)
        pool(:resource_document, :info_group).each do |doc|
          next unless ALLOWED_UNAMES.include?(doc['UNAME'])

          res = skeleton.clone
          res.attributes = deep_copy(res.attributes)
          change_resource_tpl! res, doc
          clean_unused! res.attributes

          model << res
        end
      end

      # :nodoc:
      def change_resource_tpl!(res, doc)
        res.schema = change_namespace(res.schema)
        res.location = URI.parse("/mixin/resource_tpl/#{doc.term}")
        RES_TPL_CONTENT.each { |k| res.send("#{k}=", doc.send(k)) }
        RES_TPL_ATTRS.each { |a| res[a].default = doc.body[a] }
      end

      # :nodoc:
      def add_floatingippools!(model, skeleton)
        pool(:virtual_network, :info_all).each do |vnet|
          next if vnet['PARENT_NETWORK_ID'].present? || vnet['TEMPLATE/FLOATING_IP_POOL'].blank?
          next unless vnet['TEMPLATE/FLOATING_IP_POOL'].casecmp('yes')

          flt = skeleton.clone
          change_floatingippool! flt, vnet

          model << flt
        end
      end

      # :nodoc:
      def change_floatingippool!(flt, vnet)
        flt.term = vnet['ID']
        flt.title = "Floating IP Pool - #{vnet['NAME']}"
        flt.schema = change_namespace(flt.schema)
        flt.location = URI.parse("/mixin/floatingippool/#{vnet['ID']}")
      end

      # :nodoc:
      def change_default_connectivity!(model)
        dcm = model.find_by_identifier!(Occi::InfrastructureExt::Constants::DEFAULT_CONNECT_MIXIN)
        dcm['eu.egi.fedcloud.compute.default_connectivity'].default = default_connectivity
      end

      # :nodoc:
      def clean_unused!(attributes)
        attributes.delete_if { |_, v| v.nil? || v.default.nil? }
      end

      # :nodoc:
      def deep_copy(object)
        # TODO: move this to rOCCI-core
        Marshal.load(Marshal.dump(object))
      end

      # :nodoc:
      def change_namespace(schema)
        schema.gsub EXCHANGEABLE_NAMESPACE, options.fetch(:schema_namespace)
      end
    end
  end
end
