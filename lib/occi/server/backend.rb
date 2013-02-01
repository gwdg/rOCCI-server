module Occi
  module Server
    module Backend
      attr_accessor :backends
      #compute = Frontend.backend.infrastructure.compute

      def self.register(backends)
        @backends ||= Hashie::Mash.new

        attributes = backends.dup # prevent delete from having side effects
        backends = backends.delete(:backends).to_s.downcase.to_sym

        backends.each do |layer_backend|
          require "occi/server/backend/#{layer_backend.to_s.downcase}"
          #...new :layer_backend => layer_backend
        end
      end
    end
  end
end