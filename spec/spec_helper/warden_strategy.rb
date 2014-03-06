module Warden
  module Test
    # Environment helpers for Warden requests
    module StrategyHelper
      # Prepares mocked environment for a Warden test
      def self.env_with_params(path = "/", params = {}, env = {})
        method = params.delete(:method) || "GET"
        env = { 'HTTP_VERSION' => '1.1', 'REQUEST_METHOD' => "#{method}" }.merge(env)
        Rack::MockRequest.env_for("#{path}?#{Rack::Utils.build_query(params)}", env)
      end
    end
  end
end
