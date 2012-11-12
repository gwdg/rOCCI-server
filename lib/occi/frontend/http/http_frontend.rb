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
            username     = @backend.get_username(cert_subject)

            OCCI::Log.debug "Cert Subject: #{cert_subject}"
            OCCI::Log.debug "Username: #{username.inspect}"
            OCCI::Log.debug "Username nil?: #{username.nil?}"

            server.halt 403, "User with DN #{cert_subject} could not be authenticated" if username.nil?
            username
          else
            'anonymous'
          end
        end
      end
    end
  end
end