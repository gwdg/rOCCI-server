class UnauthorizedController < ActionController::Metal
  include ActionController::RackDelegation

  def self.call(env)
    @respond ||= action(:respond)
    @respond.call(env)
  end

  def respond
    Rails.logger.warn "[AuthN] [#{self.class}] Authentication failed: #{warden_message}"
    set_unauth
    Rails.logger.warn "[AuthN] [#{self.class}] Responding with #{status} #{headers.inspect}"
  end

  def self.default_url_options(*args)
    defined?(ApplicationController) ? ApplicationController.default_url_options(*args) : {}
  end

  protected

  def set_unauth
    self.status = 401

    # Include Keystone URI in the response, if applicable
    if ROCCI_SERVER_CONFIG.common.authn_strategies.include?('keystone')
      headers['WWW-Authenticate'] = %(Keystone uri='#{ROCCI_SERVER_CONFIG.authn_strategies.keystone_.keystone_uri || "http://localhost:5000/"}')
    end

    self.content_type = 'text/plain'
    self.response_body = warden_message
  end

  def warden
    request.env['warden']
  end

  def warden_options
    request.env['warden.options']
  end

  def warden_message
    @message ||= warden.message || warden_options[:message] || "Authentication failed!" \
                 " The following strategies are supported #{ROCCI_SERVER_CONFIG.common.authn_strategies.join(', ').inspect}!"
  end

  def scope
    @scope ||= warden_options[:scope]
  end

  def attempted_path
    warden_options[:attempted_path]
  end
end
