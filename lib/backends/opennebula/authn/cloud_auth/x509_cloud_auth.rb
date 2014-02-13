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

module Backends::Opennebula::Authn::CloudAuth
  module X509CloudAuth
    def do_auth(params = {})
      fail Backends::Errors::AuthenticationError, 'Credentials for X.509 not set!' unless params && params[:client_cert_dn]

      # Password should be DN with whitespaces removed.
      username = get_username(X509Auth.escape_dn(params[:client_cert_dn]))
      return nil if username.blank?

      username
    end
  end
end
