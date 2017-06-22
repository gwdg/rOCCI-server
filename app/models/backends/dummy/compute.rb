require 'backends/dummy/base'

module Backends
  module Dummy
    class Compute < Base
      include Entitylike
    end
  end
end
