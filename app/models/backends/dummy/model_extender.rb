require 'backends/dummy/base'

module Backends
  module Dummy
    class ModelExtender < Base
      include Extenderlike
    end
  end
end
