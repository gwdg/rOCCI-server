# Private attribute accessors
module PrivateAttrAccessor
  # Defines attribute accessors in a private context
  #
  # @param names [Array] attribute names as symbols
  def private_attr_accessor(*names)
    private
    attr_accessor *names
  end

  # Defines attribute readers in a private context
  #
  # @param names [Array] attribute names as symbols
  def private_attr_reader(*names)
    private
    attr_reader *names
  end

  # Defines attribute writers in a private context
  #
  # @param names [Array] attribute names as symbols
  def private_attr_writer(*names)
    private
    attr_writer *names
  end
end
