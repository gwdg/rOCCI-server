module Backends::Ec2::Authn
  class Ec2CredentialsHelper

    # Converts given user credentials to credentials supported
    # by AWS. Currently only 'basic', 'x509' and 'voms' are
    # supported as the initial credentials.
    #
    # @param options [Hash] backend options
    # @param delegated_user [Hash] current authenticated user
    # @param logger [Logger] instance of the logging facility
    # @return [::Aws::Credentials] credentials for the AWS EC2 client
    # @effects <i>none</i>: call answered from within the backend
    def self.get_credentials(options, delegated_user, logger)
      case delegated_user.auth_.type
      when 'basic'
        # using provided basic credentials as access_key_id and secret_access_key
        handle_basic(options, delegated_user, logger)
      when 'x509'
        # everyone will be mapped to the same AWS account
        handle_x509(options, delegated_user, logger)
      when 'voms'
        # similar to 'x509', different VOs can be mapped to different AWS accounts
        handle_voms(options, delegated_user, logger)
      else
        # unsupported authentication type
        fail Backends::Errors::AuthenticationError, "Authentication strategy " \
             "#{delegated_user.auth_.type.inspect} is not supported by the EC2 backend!"
      end
    end

    private

    # Converts given basic credentials to credentials supported
    # by AWS. Username is used as access_key_id and password as
    # secret_access_key.
    #
    # @param options [Hash] backend options
    # @param delegated_user [Hash] current authenticated user
    # @param logger [Logger] instance of the logging facility
    # @return [::Aws::Credentials] credentials for the AWS EC2 client
    def self.handle_basic(options, delegated_user, logger)
      fail Backends::Errors::AuthenticationError, 'User could not be authenticated, ' \
           'username is missing!' if delegated_user.auth_.credentials_.username.blank?
      fail Backends::Errors::AuthenticationError, 'User could not be authenticated, ' \
           'password is missing!' if delegated_user.auth_.credentials_.password.blank?

      ::Aws::Credentials.new(
        delegated_user.auth_.credentials_.username,
        delegated_user.auth_.credentials_.password
      )
    end

    # Converts given X.509 credentials to credentials supported
    # by AWS. All users will get access to the same set of AWS
    # credentials configured in the backend configuration file.
    #
    # @param options [Hash] backend options
    # @param delegated_user [Hash] current authenticated user
    # @param logger [Logger] instance of the logging facility
    # @return [::Aws::Credentials] credentials for the AWS EC2 client
    def self.handle_x509(options, delegated_user, logger)
      fail Backends::Errors::AuthenticationError, 'User could not be authenticated, ' \
           'global access_key_id is missing!' if options.access_key_id.blank?
      fail Backends::Errors::AuthenticationError, 'User could not be authenticated, ' \
           'global secret_access_key is missing!' if options.secret_access_key.blank?

      ::Aws::Credentials.new(options.access_key_id, options.secret_access_key)
    end

    # Converts given VOMS credentials to credentials supported
    # by AWS. All users will get access to the same set of AWS
    # credentials configured in the backend configuration file.
    # It is possible to provide different sets of credentials for
    # different VOs. See the configuration file for details.
    #
    # @param options [Hash] backend options
    # @param delegated_user [Hash] current authenticated user
    # @param logger [Logger] instance of the logging facility
    # @return [::Aws::Credentials] credentials for the AWS EC2 client
    def self.handle_voms(options, delegated_user, logger)
      # select the first VO
      # TODO: What to do with multiple VOs?
      first_vo = (delegated_user.auth_.credentials_.client_cert_voms_attrs || []).first
      fail Backends::Errors::AuthenticationError, 'Malformed VOMS credentials, ' \
           'required extension attributes are missing!' unless first_vo && !first_vo.vo.blank?

      logger.debug "[Backends] [Ec2Backend] Searching for VO -> AWS " \
                   "account mapping for #{first_vo.vo.inspect}"
      if !options.vo_aws_mapfile.blank?
        # we have a mapfile with VO -> AWS account entries
        vo_aws_mapfile = AuthenticationStrategies::Helpers::YamlHelper.read_yaml(options.vo_aws_mapfile)

        # look-up the VO name
        if vo_aws_mapfile.include?(first_vo.vo)
          # mapping was provided, use it
          logger.debug "[Backends] [Ec2Backend] Found mapping for " \
                       "#{first_vo.vo.inspect} in #{options.vo_aws_mapfile.inspect}"
          ::Aws::Credentials.new(
            vo_aws_mapfile[first_vo.vo].access_key_id,
            vo_aws_mapfile[first_vo.vo].secret_access_key
          )
        else
          # no mapping was provided, use the global default
          logger.debug "[Backends] [Ec2Backend] No mapping for " \
                       "#{first_vo.vo.inspect} in #{options.vo_aws_mapfile.inspect}"
          handle_x509(options, delegated_user, logger)
        end
      else
        # no mapfile was provided
        logger.debug "[Backends] [Ec2Backend] No VO -> AWS account mapfile was provided!"
        handle_x509(options, delegated_user, logger)
      end
    end

  end
end
