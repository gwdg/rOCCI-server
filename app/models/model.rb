# Provides access to Occi::Model instances with added
# functionality:
# * Wraps Occi::Model instantiation
# * Automatically performs necessary registrations
# * Helps with filtering
class Model

  class << self

    # Instantiates Occi::Model and registers necessary extensions.
    #
    # @example
    #    Model.get #=> #<Occi::Model>
    #
    # @return [Occi::Model] an Occi::Model instance ready to use
    def get
      model_factory
    end

    # Instantiates Occi::Model, registers necessary extensions
    # and filters its content according to `filter`.
    #
    # @example
    #    Model.get_filtered(collection) #=> Occi::Model
    #
    # @param filter [Occi::Collection, Occi::Core::Category, String] filtration parameters
    # @return [Occi::Model] an Occi::Model instance ready to use
    def get_filtered(filter)
      filter = filter.kinds.first if filter.respond_to?(:kinds)
      model_factory.get(filter)
    end

    private

    # Instantiates Occi::Model and registers necessary extensions
    # according to `with_extensions`. Extensions inlcude `resource_tpl`
    # and `os_tpl` mixins, new kinds and actions etc.
    #
    # @param with_extensions [true, false] flag allowing backend-specific extensions
    # @return [Occi::Model] an Occi::Model instance ready to use
    def model_factory(with_extensions = true)
      model = Occi::Model.new
      model.register_infrastructure

      if with_extensions
        model.register_collection(Backend.instance.model_get_extensions)
        model.register_collection(Backend.instance.os_tpl_get_all)
        model.register_collection(Backend.instance.resource_tpl_get_all)
      end

      model
    end

  end

end