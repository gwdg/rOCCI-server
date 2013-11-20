# Be sure to restart your server when you modify this file.
if Rails.env.production?
  require 'action_dispatch/middleware/session/dalli_store'
  ROCCIServer::Application.config.session_store :dalli_store, :memcache_server => ['localhost'], :namespace => 'sessions', :key => '_foundation_session', :expire_after => 20.minutes
else
  ROCCIServer::Application.config.session_store :cookie_store, key: '_rOCCI-server_session'
end