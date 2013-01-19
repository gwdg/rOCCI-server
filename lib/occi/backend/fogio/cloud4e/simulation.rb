module OCCI
  module Backend
    class Fogio
      module Cloud4e
        class Simulation
          attr_accessor :model

          def initialize(model)
            @model = model
          end

          def deploy(client, simulation)

          end
        end
      end
    end
  end
end