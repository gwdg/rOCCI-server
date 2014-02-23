# Be sure to restart your server when you modify this file.
if Rails.env.production?
  require 'action_dispatch/middleware/session/dalli_store'
  namespace = "sessions_#{ROCCI_SERVER_CONFIG.common.hostname}_#{ROCCI_SERVER_CONFIG.common.port}"
  ROCCIServer::Application.config.session_store :dalli_store, memcache_server: ROCCI_SERVER_CONFIG.common.memcaches,
                                                namespace: namespace, key: '_foundation_session', expire_after: 20.minutes
else
  ROCCIServer::Application.config.session_store :cookie_store, key: '_rOCCI-server_session'
end
