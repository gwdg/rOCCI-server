require 'backends/dummy/base'

module Backends
  module Dummy
    class Storage < Base
      include Entitylike
    end
  end
end
