# -------------------------------------------------------------------------- #
# Copyright 2002-2013, OpenNebula Project (OpenNebula.org), C12G Labs        #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

require 'openssl'
require 'digest/sha1'

require 'base64'
require 'fileutils'

module Backends::Opennebula::Authn::CloudAuth
  # Server authentication class. This method can be used by OpenNebula services
  # to let access authenticated users by other means. It is based on OpenSSL
  # symmetric ciphers
  class ServerCipherAuth
    ###########################################################################
    # Constants with paths to relevant files and defaults
    ###########################################################################
    CIPHER = 'aes-256-cbc'

    def initialize(srv_user, srv_passwd)
      @srv_user   = srv_user
      @srv_passwd = srv_passwd

      if !srv_passwd.blank?
          @key = ::Digest::SHA1.hexdigest(@srv_passwd)
      else
          @key = ''
      end

      @cipher = ::OpenSSL::Cipher::Cipher.new(CIPHER)
    end

    # Creates a ServerCipher for client usage
    def self.new_client(srv_user, srv_passwd)
      new(srv_user, srv_passwd)
    end

    # Generates a login token in the form:
    #   - server_user:target_user:time_expires
    # The token is then encrypted with the contents of one_auth
    def login_token(expire, target_user = nil)
      target_user ||= @srv_user
      token_txt   =   "#{@srv_user}:#{target_user}:#{expire}"

      token   = encrypt(token_txt)
      token64 = ::Base64.encode64(token).strip.delete("\n")

      "#{@srv_user}:#{target_user}:#{token64}"
    end

    # Returns a valid password string to create a user using this auth driver
    def password
        @srv_passwd
    end

    private

    def encrypt(data)
      @cipher.encrypt
      @cipher.key = @key

      rc = @cipher.update(data)
      rc << @cipher.final

      rc
    end

    def decrypt(data)
      @cipher.decrypt
      @cipher.key = @key

      rc = @cipher.update(::Base64.decode64(data))
      rc << @cipher.final

      rc
    end
  end
end
