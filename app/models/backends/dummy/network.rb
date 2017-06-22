require 'backends/dummy/base'

module Backends
  module Dummy
    class Network < Base
      include Entitylike
    end
  end
end
