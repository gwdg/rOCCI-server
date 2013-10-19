module Backends
  class Dummy

    def initialize(options = {}, credentials = {}, extensions = {})
      @options = options
      @credentials = credentials
      @extensions = extensions
    end

    include Backends::Compute::Dummy
    include Backends::Network::Dummy
    include Backends::Storage::Dummy
    include Backends::OsTpl::Dummy
    include Backends::ResourceTpl::Dummy

  end
end