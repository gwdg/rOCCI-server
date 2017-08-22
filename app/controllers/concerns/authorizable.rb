module Authorizable
  extend ActiveSupport::Concern

  # Header key const
  REDIRECT_HEADER_KEY = 'WWW-Authenticate'.freeze

  included do
    before_action :authorize_user!
  end

  class_methods do
    # Returns HTTP header key for authentication URI.
    #
    # @return [String] header key for authentication URI
    def redirect_header_key
      REDIRECT_HEADER_KEY
    end

    # Returns URI for authentication redirect.
    #
    # @return [String] authentication URI
    def redirect_header_uri
      "Keystone uri='#{app_config.fetch('keystone_uri')}'"
    end
  end

  # Returns name of the authorized user or `unauthorized`.
  #
  # @return [String] user name
  def current_user
    authorize_user!
    @_current_user
  end

  # Returns token of the authenticated user or `nil`.
  #
  # @return [String] user token
  def current_token
    authorize_user!
    @_current_token
  end

  # Checks for pending (not yet performed) authorization.
  #
  # @return [TrueClass] authorization pending
  # @return [FalseClass] authorization not pending
  def authorization_pending?
    @_user_authorized.nil?
  end

  # Forces immediate user authorization and set appropriate attributes.
  #
  # @return [String] user name
  def authorize_user!
    return unless authorization_pending?
    logger.debug "User authorization data #{request_user.inspect}:#{request_token.inspect}" if logger_debug?

    request_authorized? ? authorize_set! : authorize_unset!
  end

  # Sets variables for authorized user.
  #
  # @return [String] user name
  def authorize_set!
    @_user_authorized = true
    @_current_token = request_token
    @_current_user = request_user
  end

  # Sets variables for unauthorized user.
  #
  # @return [String] static 'unauthorized' string
  def authorize_unset!
    @_user_authorized = false
    @_current_token = nil
    @_current_user = 'unauthorized'
  end

  # :nodoc:
  def request_token
    request.env['rocci_server.request.tokenator.token'].strip
  end

  # :nodoc:
  def request_user
    request.env['rocci_server.request.tokenator.user'].strip
  end

  # :nodoc:
  def request_authorized?
    request.env['rocci_server.request.tokenator.authorized']
  end
end
