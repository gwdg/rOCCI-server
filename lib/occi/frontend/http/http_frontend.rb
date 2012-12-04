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

            # Lookup failed with SSL_CLIENT_S_DN, we should try handling the certificate as a VOMS proxy
            if username.nil?
              OCCI::Log.debug "User not found! Attempting to handle proxy certificates..."
              cert_subject = check_voms_proxy_cert

              OCCI::Log.debug "Looking for user #{cert_subject}"
              username     = @backend.get_username(cert_subject)
            end

            OCCI::Log.debug "Username: #{username ? username : 'nil' }"

            halt 403, "User with DN #{cert_subject} could not be authenticated" if username.nil?
            username
          else
            'anonymous'
          end
        end

        def check_voms_proxy_cert
          proxy_cert_subject = nil

          # Proxy certs append CNs, we have to find the last one
          last_cn = 0
          (1..256).each do |i|
            if request.env["SSL_CLIENT_S_DN_CN_#{i}"]
              last_cn = i
            else
              break
            end
          end

          # Proxy cert has to have at least SSL_CLIENT_S_DN_CN_1
          if last_cn > 0
            # Just to be sure, we should get issuer's DN
            # and compare it to subject's DN
            cert_issuer = request.env['SSL_CLIENT_I_DN']
            proxy_cn = request.env["SSL_CLIENT_S_DN_CN_#{last_cn}"]
            proxy_cert_subject = request.env['SSL_CLIENT_S_DN'].gsub("/CN=#{proxy_cn}", '')

            OCCI::Log.debug "Proxy DN: #{proxy_cert_subject}?"
            if proxy_cert_subject == cert_issuer
              # SSL_CLIENT_CERT should contain client's certificate
              if request.env['SSL_CLIENT_CERT']
                # Read client's certificate
                proxy_cert = OpenSSL::X509::Certificate.new request.env['SSL_CLIENT_CERT']

                # Iterate through available extensions
                voms_ary = nil
                proxy_cert.extensions.each do |ext|
                  # Find VOMS extensions using their OID
                  if ext.oid == "1.3.6.1.4.1.8005.100.100.5"
                    # Parse group and role from cert extension
                    # TODO: use ASN1 or mod_gridsite
                    voms_ary = /\*\/(.+)\/Role=(.+)\/Capability=NULL/.match ext.value
                    OCCI::Log.debug "VOMS ext: group=#{voms_ary[1]} role=#{voms_ary[2]}"
                  end
                end

                # Append found values to user's DN
                if voms_ary && voms_ary[1] && voms_ary[2]
                  proxy_cert_subject = proxy_cert_subject << "/VO=#{voms_ary[1]}/Role=#{voms_ary[2]}/Capability=NULL"
                end
              else
                OCCI::Log.warn "SSL_CLIENT_CERT is not available, add +ExportCertData to SSLOptions!"
              end
            else
              OCCI::Log.warn "Issuer DN doesn't match stripped cert DN, I won't accept this proxy!"
              proxy_cert_subject = nil
            end
          end

          proxy_cert_subject
        end

      end
    end
  end
end
