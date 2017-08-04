module Backends
  module Opennebula
    class Storage < Base
      include Entitylike
      include AttributesTransferable
      include MixinsAttachable

      class << self
        # @see `served_class` on `Entitylike`
        def served_class
          Occi::Infrastructure::Storage
        end

        # :nodoc:
        def entity_identifier
          Occi::Infrastructure::Constants::STORAGE_KIND
        end
      end

      # @see `Entitylike`
      def identifiers(_filter = Set.new)
        Set.new(pool(:image, :info_mine).map { |im| im['ID'] })
      end

      # @see `Entitylike`
      def list(_filter = Set.new)
        coll = Occi::Core::Collection.new
        pool(:image, :info_mine).each { |image| coll << storage_from(image) }
        coll
      end

      # @see `Entitylike`
      def instance(identifier)
        image = ::OpenNebula::Image.new_with_id(identifier, raw_client)
        client(Errors::Backend::EntityStateError) { image.info }
        storage_from(image)
      end

      # @see `Entitylike`
      def delete(identifier)
        image = ::OpenNebula::Image.new_with_id(identifier, raw_client)
        client(Errors::Backend::EntityStateError) { image.delete }
      end

      private

      # Converts a ONe image instance to a valid storage instance.
      #
      # @param image [OpenNebula::Image] instance to transform
      # @return [Occi::Infrastructure::Storage] transformed instance
      def storage_from(image)
        storage = instance_builder.get(self.class.entity_identifier)

        attach_mixins! image, storage
        transfer_attributes! image, storage, Constants::Storage::TRANSFERABLE_ATTRIBUTES

        storage
      end

      # :nodoc:
      def attach_mixins!(image, storage)
        storage << server_model.find_regions.first

        ds = ::OpenNebula::Datastore.new_with_id(image['DATASTORE_ID'], raw_client)
        client(Errors::Backend::EntityStateError) { ds.info }
        ds.each_xpath('CLUSTERS/ID') do |cid|
          attach_optional_mixin! storage, cid, :availability_zone
        end
      end
    end
  end
end
