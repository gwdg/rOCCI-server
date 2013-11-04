class Model

  class << self

    def get
      model_factory
    end

    def get_filtered(filter)
      filter = filter.kinds.first if filter.respond_to?(:kinds)
      model_factory.get(filter)
    end

    private

    def model_factory(with_extensions = true)
      model = Occi::Model.new
      model.register_infrastructure

      if with_extensions
        model.register_collection(Backend.instance.model_get_extensions)
      end

      model
    end

  end

end