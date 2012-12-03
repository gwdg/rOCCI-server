require "occi/frontend/base/base_frontend"

module OCCI
  module Frontend
    module Http
      class HttpFrontend < OCCI::Frontend::Base::BaseFrontend
        def initialize()
          log("debug", __LINE__, "Initialize HTTPFrontend")
          super
        end

        # @param [OCCI::Frontend::Http::HttpRequest] request
        # @return [String]
        def check_authorization(request)
          #
          #  # TODO: investigate usage fo expiration time and session cookies
          #  expiration_time = Time.now.to_i + 1800
          #
          #  token = @one_auth.login_token(expiration_time, username)
          #
          #  Client.new(token, @en
          basic_auth  = Rack::Auth::Basic::Request.new(request.env)
          digest_auth = Rack::Auth::Digest::Request.new(request.env)
          if basic_auth.provided? && basic_auth.basic?
            username, password = basic_auth.credentials
            server.halt 403, "Password in request does not match password of user #{username}" unless @backend.authorized?(username, password)
            puts "basic auth successful"
            username
          elsif digest_auth.provided? && digest_auth.digest?
            username, password = digest_auth.credentials
            server.halt 403, "Password in request does not match password of user #{username}" unless @backend.authorized?(username, password)
            username
          elsif request.env['SSL_CLIENT_S_DN']
            # For https, the web service should be set to include the user cert in the environment.

            cert_subject = request.env['SSL_CLIENT_S_DN']
            # Password should be DN with whitespace removed.
            OCCI::Log.debug "Looking for: #{cert_subject}"
            username     = @backend.get_username(cert_subject)

            if username.nil?
              OCCI::Log.debug "User not found! Attempting to handle proxy certificates..."

              OCCI::Log.debug "Looking for SSL_CLIENT_S_DN_CN_* env variables..."
              last_cn = 0
              (1..10).each do |i|
                if request.env["SSL_CLIENT_S_DN_CN_#{i}"]
                  last_cn = i
                else
                  break
                end
              end

              if last_cn > 0
                cert_issuer = request.env['SSL_CLIENT_I_DN']
                proxy_cn = request.env["SSL_CLIENT_S_DN_CN_#{last_cn}"]
                proxy_subject = request.env['SSL_CLIENT_S_DN'].gsub("/CN=#{proxy_cn}", '')

                OCCI::Log.debug "#{proxy_subject} == #{cert_issuer}?"

                if proxy_subject == cert_issuer
                  username = @backend.get_username(cert_issuer)
                else
                  OCCI::Log.debug "Issuer DN doesn't match stripped cert DN, I won't accept this proxy!"
                  username = nil
                end
              else
                OCCI::Log.debug "This is not a RFC compliant proxy certificate, there is nothing I can do!"
              end
            end

            OCCI::Log.debug "Username: #{username ? username : 'nil' }"

            halt 403, "User with DN #{cert_subject} could not be authenticated" if username.nil?
            username
          else
            'anonymous'
          end
        end
      end
    end
  end
end
