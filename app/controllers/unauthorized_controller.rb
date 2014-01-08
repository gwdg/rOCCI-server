class UnauthorizedController < ActionController::Metal
  include ActionController::RackDelegation

  def self.call(env)
    @respond ||= action(:respond)
    @respond.call(env)
  end

  def respond
    Rails.logger.warn "[AuthN] [#{self.class}] Authentication failed: #{warden_message}"
    set_unauth ROCCI_SERVER_CONFIG.common.authn_strategies.include?('keystone')
    Rails.logger.debug "[AuthN] [#{self.class}] Responding with #{self.status} #{self.headers.inspect}"
  end

  def self.default_url_options(*args)
    if defined?(ApplicationController)
      ApplicationController.default_url_options(*args)
    else
      {}
    end
  end

  protected

  def set_unauth(keystone = false)
    self.status = 401
    self.headers["WWW-Authenticate"] = %(Keystone uri=#{"test"}) if keystone
    self.content_type = 'text/plain'
    self.response_body = warden_message
  end

  def warden
    env['warden']
  end

  def warden_options
    env['warden.options']
  end

  def warden_message
    @message ||= warden.message || warden_options[:message]
  end

  def scope
    @scope ||= warden_options[:scope]
  end

  def attempted_path
    warden_options[:attempted_path]
  end
end