class Model

  def self.collection
    self.model_factory
  end

  private

  def self.model_factory(with_mixins = true)
    model = Occi::Model.new
    model.register_infrastructure

    if with_mixins
      # TODO: get stuff from MongoDB and the backend
      #model.register_files
    end

    model
  end

end