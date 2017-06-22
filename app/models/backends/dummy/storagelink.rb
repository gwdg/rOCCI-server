require 'backends/dummy/base'

module Backends
  module Dummy
    class Storagelink < Base
      include Entitylike
    end
  end
end
