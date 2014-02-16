module ActionDispatch::Assertions::RoutingAssertions
  def message(string, default, &block)
    block.call
  end
end
