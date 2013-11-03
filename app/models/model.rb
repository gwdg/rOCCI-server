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
        # TODO: get stuff from MongoDB and the backend
        #model.register_files
      end

      model
    end

  end

end