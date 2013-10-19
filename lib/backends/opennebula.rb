module Backends
  class Opennebula

    def initialize(options = {}, credentials = {}, extensions = {})
      @options = options
      @credentials = credentials
      @extensions = extensions
    end

  end
end