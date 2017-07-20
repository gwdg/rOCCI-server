module Backends
  module Opennebula
    class Warehouse < ::Occi::Core::Warehouse
      class << self
        protected

        # :nodoc:
        def whereami
          File.expand_path(File.dirname(__FILE__))
        end
      end
    end
  end
end
