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
            # For https, the web service should be set to include the user cert in the environment
            cert_subject = request.env['SSL_CLIENT_S_DN']

            # Password should be DN with whitespaces removed
            OCCI::Log.debug "Looking for user #{cert_subject}"
            username     = @backend.get_username(cert_subject)

            # Lookup failed with SSL_CLIENT_S_DN, try handling the certificate as a proxy
            # This requires mod_gridsite ENV variables GRST_CRED_*
            if username.nil? && request.env['GRST_CRED_0']
              OCCI::Log.debug "Attempting to handle proxy certificates..."
              cert_subject = check_proxy_cert

              OCCI::Log.debug "Looking for user #{cert_subject}"
              username     = @backend.get_username(cert_subject)
            end

            OCCI::Log.debug "Username: #{username ? username : 'nil' }"

            halt 403, "User with DN #{cert_subject} could not be authenticated" if username.nil?
            username
          elsif request.env['HTTP_X_AUTH_TOKEN']
            username = @backend.get_username(request.env['HTTP_X_AUTH_TOKEN'], "KEYSTONE")
            #TODO make better implementation
            @backend.authorized?(username, request.env['HTTP_X_AUTH_TOKEN'])
            username
          else
            'anonymous'
          end
        end

        def check_proxy_cert
          OCCI::Log.debug "Looking for GRST_CRED_{1,2} env variables..."

          # Here is a sample of the structures parsed below:
          # "GRST_CRED_0"=>"X509USER 1341878400 1376092799 1 /DC=org/DC=terena/DC=tcs/C=CZ/O=Masaryk University/CN=My Name"
          # "GRST_CRED_1"=>"GSIPROXY 1354921680 1354965180 1 /DC=org/DC=terena/DC=tcs/C=CZ/O=Masaryk University/CN=My Name/CN=447432737"
          # "GRST_CRED_2"=>"VOMS 140365809703311 1354965180 0 /vo.example.org/Role=NULL/Capability=NULL"

          grst_cred_regexp = /(.+)\s(\d+)\s(\d+)\s(\d)\s(.+)/
          grst_voms_regexp = /\/(.+)\/Role=(.+)\/Capability=(.+)/
          proxy_cert_subject = nil

          # Proxy cert has to have GRST_CRED_1 set
          if request.env['GRST_CRED_1']
            # Get user's DN
            proxy_cert_subject = grst_cred_regexp.match(request.env['GRST_CRED_0'])[5]

            # Get VOMS extension
            if proxy_cert_subject && request.env['GRST_CRED_2']
              # Parse extension and drop useless first element of MatchData
              voms_ext = grst_cred_regexp.match request.env['GRST_CRED_2']
              voms_ext = voms_ext.to_a.drop 1

              if voms_ext && voms_ext[0] == "VOMS"
                # Parse group, role and capability from VOMS extension
                voms_ary = grst_voms_regexp.match voms_ext[4]

                # Append found values to user's DN
                if voms_ary && voms_ary[1] && voms_ary[2] && voms_ary[3]
                  OCCI::Log.debug "VOMS ext: vo=#{voms_ary[1]} role=#{voms_ary[2]} capability=#{voms_ary[3]}"
                  proxy_cert_subject = proxy_cert_subject << "/VO=#{voms_ary[1]}/Role=#{voms_ary[2]}/Capability=#{voms_ary[3]}"
                end
              else
                OCCI::Log.warn "This VOMS extension seems to be malformed! #{request.env['GRST_CRED_2']}"
              end
            else
              OCCI::Log.debug "This proxy certificate doesn't contain VOMS extensions!"
            end
          else
            OCCI::Log.debug "This is not a RFC compliant proxy certificate!"
          end

          proxy_cert_subject
        end

      end
    end
  end
end
