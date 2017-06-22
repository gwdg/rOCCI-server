require 'backends/dummy/base'

module Backends
  module Dummy
    class Securitygroup < Base
      include Entitylike
    end
  end
end
