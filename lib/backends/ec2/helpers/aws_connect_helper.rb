module Backends
  module Ec2
    module Helpers
      module AwsConnectHelper

        def self.rescue_aws_service(logger)
          begin
            yield
          rescue ::Seahorse::Client::Http::Error => e
            logger.error "[Backends] [Ec2Backend] #{e.message}"
            fail Backends::Errors::ServiceUnavailableError, e.message
          end
        end

      end
    end
  end
end
