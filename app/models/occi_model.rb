# Provides access to Occi::Model instances with added
# functionality:
# * Wraps Occi::Model instantiation
# * Automatically performs necessary registrations
# * Helps with filtering
class OcciModel
  class << self
    # Instantiates Occi::Model and registers necessary extensions.
    #
    # @example
    #    backend = Backend.new
    #    OcciModel.get(backend) #=> #<Occi::Model>
    #
    # @param backend [Backend] instance of the currently active backend
    # @param filter [Occi::Collection, Occi::Core::Category, String] filtration parameters
    # @return [Occi::Model] an Occi::Model instance ready to use
    def get(backend, filter = nil)
      fail ArgumentError, 'Backend is a mandatory argument!' unless backend
      filter ? get_filtered(backend, filter) : model_factory(backend)
    end

    # Instantiates Occi::Model, registers necessary extensions
    # and filters its content according to `filter`.
    #
    # @example
    #    backend = Backend.new
    #    OcciModel.get_filtered(backend, collection) #=> Occi::Model
    #
    # @param backend [Backend] instance of the currently active backend
    # @param filter [Occi::Collection, Occi::Core::Category, String] filtration parameters
    # @return [Occi::Model] an Occi::Model instance ready to use
    def get_filtered(backend, filter)
      fail ArgumentError, 'Backend is a mandatory argument!' unless backend
      fail ArgumentError, 'Filter is a mandatory argument!' unless filter

      Rails.logger.debug "[#{self}] Building OCCI model with filter: #{filter.inspect}"
      single_filter = filter.kinds.first if filter.respond_to?(:kinds)
      single_filter = filter.mixins.first if single_filter.blank? && filter.respond_to?(:mixins)
      model_factory(backend).get(single_filter)
    end

    # Instantiates Occi::Model and registers necessary extensions
    # according to `with_extensions`. Extensions inlcude `resource_tpl`
    # and `os_tpl` mixins, new kinds and actions etc.
    #
    # @param backend [Backend] instance of the currently active backend
    # @param with_extensions [true, false] flag allowing backend-specific extensions
    # @return [Occi::Model] an Occi::Model instance ready to use
    def model_factory(backend, with_extensions = true)
      model = Occi::Model.new
      model.register_infrastructure

      if with_extensions
        Rails.logger.debug "[#{self}] Building OCCI model with extensions"
        model.register_collection(get_extensions(backend))
        model.register_collection(mixins_as_a_coll(backend.os_tpl_list))
        model.register_collection(mixins_as_a_coll(backend.resource_tpl_list))
      end

      model
    end

    # Gets backend-specific extensions which should be merged
    # into Occi::Model of the server.
    #
    # @example
    #    backend = Backend.new
    #    collection = get_extensions(backend) #=> #<Occi::Collection>
    #    collection.kinds   #=> #<Occi::Core::Kinds>
    #    collection.mixins  #=> #<Occi::Core::Mixins>
    #    collection.actions #=> #<Occi::Core::Actions>
    #
    # @param backend [Backend] instance of the currently active backend
    # @return [Occi::Collection] a collection of extensions containing kinds, mixins and actions
    def get_extensions(backend)
      collection = Occi::Collection.new

      # Load all JSON files in the given directory, these contain
      # JSON rendering of OCCI kind/mixin/action definitions
      path = File.join(Rails.application.config.rocci_server_etc_dir, 'backends', backend.backend_name, 'model')
      Rails.logger.debug "[#{self}] Getting extensions from #{path}"
      Dir.glob(File.join(path, '**', '*.json')) do |file|
        Rails.logger.debug "[#{self}] Reading #{file}"
        parsed = JSON.parse(File.read(file))
        coll = Occi::Collection.new(parsed)

        collection.merge! coll
      end

      collection
    end

    # Wraps given collection of mixins in an Occi::Collection instance
    #
    # @example
    #    mixins = Occi::Core::Mixins.new
    #    coll = mixins_as_a_coll(mixins) #=> #<Occi::Collection>
    #    coll.mixins == mixins #=> true
    #
    # @param mixins [Occi::Core::Mixins]
    # @return [Occi::Collection]
    def mixins_as_a_coll(mixins)
      fail ArgumentError, 'Mixins is a mandatory argument!' unless mixins
      collection = Occi::Collection.new
      collection.mixins = mixins

      collection
    end
  end

  private_class_method :model_factory
  private_class_method :get_extensions
  private_class_method :mixins_as_a_coll
end
