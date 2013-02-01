module Occi
  module Server
    module Backend
      module Infrastructure
        module Compute
          class Dummy
            def initialize(attributes)
              attributes = attributes.dup
            end
          end
        end
      end
    end
  end
end
