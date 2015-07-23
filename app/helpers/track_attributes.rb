# Tracks accessor definitions on classes.
module TrackAttributes
  def attr_readers
    self.instance_variable_get('@attr_readers') || []
  end

  def attr_writers
    self.instance_variable_get('@attr_writers') || []
  end

  def attr_accessors
    self.instance_variable_get('@attr_accessors') || []
  end

  def self.extended(klass)
    klass.send :define_singleton_method, :attr_reader, ->(*params) do
      @attr_readers ||= []
      @attr_readers.concat params
      super(*params)
    end

    klass.send :define_singleton_method, :attr_writer, ->(*params) do
      @attr_writers ||= []
      @attr_writers.concat params
      super(*params)
    end

    klass.send :define_singleton_method, :attr_accessor, ->(*params) do
      @attr_accessors ||= []
      @attr_accessors.concat params
      super(*params)
    end
  end
end