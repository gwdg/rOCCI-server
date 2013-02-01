module Occi
  module Server
    module Backend
      module Infrastructure
        module Network
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
