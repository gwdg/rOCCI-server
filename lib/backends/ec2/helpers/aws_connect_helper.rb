module Backends
  module Ec2
    module Helpers
      module AwsConnectHelper

        def self.rescue_aws_service(logger)
          begin
            yield
          rescue ::Aws::EC2::Errors::ServiceError => e
            handle_service_error(e, logger)
          rescue ::Seahorse::Client::Http::Error => e
            logger.error "[Backends] [Ec2Backend] HTTP Error: #{e.message}"
            fail Backends::Errors::ServiceUnavailableError, e.message
          end
        end

        def self.handle_service_error(error, logger)
          error_code = error.to_s.split('::').last
          message = "#{error_code}: #{error.message}"

          case error_code
          when 'AuthFailure', 'Blocked'
            fail Backends::Errors::AuthenticationError, message
          when 'CannotDelete', 'DependencyViolation', 'IncorrectState', 'DiskImageSizeTooLarge', 'IncorrectInstanceState'
            fail Backends::Errors::ResourceStateError, message
          when /^(.+)Malformed$/, /^(.+)Format$/, /^(.+)ZoneMismatch$/, /^(.+)AlreadyExists$/, /^(.+)Duplicate$/
            fail Backends::Errors::ResourceNotValidError, message
          when /^(.+)InUse$/, /^(.+)Conflict$/, /^(.+)NotSupported$/
            fail Backends::Errors::ResourceStateError, message
          when /^Insufficient(.+)Capacity$/, /^(.+)LimitExceeded$/
            fail Backends::Errors::ResourceCreationError, message
          when /^(.+)NotFound$/
            fail Backends::Errors::ResourceNotFoundError, message
          else
            # 'InternalError', 'Unavailable', ...
            fail Backends::Errors::ResourceActionError, message
          end
        end

      end
    end
  end
end
