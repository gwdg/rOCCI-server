module Backends
  class Dummy

    def initialize(options = {}, credentials = {}, extension = {})
      @options = options
      @credentials = credentials
      @extension = extension
    end

    include Backends::Compute::Dummy
    include Backends::Network::Dummy
    include Backends::Storage::Dummy
    include Backends::OsTpl::Dummy
    include Backends::ResourceTpl::Dummy

  end
end