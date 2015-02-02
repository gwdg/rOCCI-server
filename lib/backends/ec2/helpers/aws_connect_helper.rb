module Backends
  module Ec2
    module Helpers
      module AwsConnectHelper

        # Wraps calls to EC2 and provides basic error handling.
        # This method requires a block, if no block is given a
        # {Backends::Errors::StubError} error is raised.
        #
        # @example
        #     Backends::Ec2::Helpers::AwsConnectHelper.rescue_aws_service(@logger) do
        #       instance_statuses = @ec2_client.describe_instance_status.instance_statuses
        #       instance_statuses.each { |istatus| id_list << istatus[:instance_id] } if instance_statuses
        #     end
        #
        # @param logger [Logger] instance of a logging facility
        # @effects <i>none</i>: call answered from within the backend
        def self.rescue_aws_service(logger)
          fail Backends::Errors::StubError, 'AWS service-wrapper was called without a block!' unless block_given?

          begin
            yield
          rescue ::Aws::EC2::Errors::DryRunOperation => e
            logger.warn "[Backends] [Ec2Backend] DryRun: #{e.message}"
            fail Backends::Errors::MethodNotImplementedError, e.message
          rescue ::Aws::EC2::Errors::ServiceError => e
            handle_service_error(e, logger)
          rescue ::Seahorse::Client::NetworkingError => e
            logger.error "[Backends] [Ec2Backend] HTTP Error: #{e.message}"
            fail Backends::Errors::ServiceUnavailableError, e.message
          end
        end

        # Converts EC2 error codes to errors understood by rOCCI-server.
        # This method will ALWAYS raise an error.
        # See http://docs.aws.amazon.com/AWSEC2/latest/APIReference/api-error-codes.html
        #
        # @param error [Aws::EC2::Errors::ServiceError] EC2 error instance
        # @param logger [Logger] instance of a logging facility
        # @effects <i>none</i>: call answered from within the backend
        def self.handle_service_error(error, logger)
          error_code = error.class.to_s.split('::').last
          message = "#{error_code}: #{error.message}"

          case error_code
          when 'Unavailable'
            # service is not available, probably EC2's fault
            fail Backends::Errors::ServiceUnavailableError, message
          when 'AuthFailure', 'Blocked', 'SignatureDoesNotMatch'
            # something is wrong with our credentials
            fail Backends::Errors::AuthenticationError, message
          when 'CannotDelete', 'DependencyViolation', 'IncorrectState', 'IncorrectInstanceState'
            # action wasn't allowed in this state or context
            fail Backends::Errors::ResourceStateError, message
          when /^(.+)Format$/, /^(.+)ZoneMismatch$/, /^(.+)AlreadyExists$/, /^(.+)Duplicate$/
            # something was wrong with our request
            fail Backends::Errors::ResourceNotValidError, message
          when /^(.+)InUse$/, /^(.+)Conflict$/, /^(.+)NotSupported$/
            # again, wrong state to perform the given action
            fail Backends::Errors::ResourceStateError, message
          when /^Insufficient(.+)Capacity$/, /^(.+)LimitExceeded$/, 'DiskImageSizeTooLarge'
            # not enough resources or requesting too much for current limits
            fail Backends::Errors::ResourceCreationError, message
          when /^(.+)Malformed$/, 'InvalidParameterValue'
            # what we sent was malformed or didn't have the proper format
            fail Backends::Errors::IdentifierNotValidError, message
          when /^(.+)NotFound$/
            #
            fail Backends::Errors::ResourceNotFoundError, message
          else
            # 'InternalError', ...
            fail Backends::Errors::ResourceActionError, message
          end
        end

      end
    end
  end
end
