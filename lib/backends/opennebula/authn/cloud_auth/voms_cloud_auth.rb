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
  module VomsCloudAuth
    def do_auth(params = {})
      fail Backends::Errors::AuthenticationError, 'Credentials for X.509 not set!' unless params && params[:client_cert_dn]
      fail Backends::Errors::AuthenticationError, 'Attributes for VOMS not set!' unless params[:client_cert_voms_attrs] && params[:client_cert_voms_attrs].first

      # TODO: interate through all available sets of attrs?
      first_voms = params[:client_cert_voms_attrs].first

      if first_voms[:vo].blank? || first_voms[:role].blank? || first_voms[:capability].blank?
        fail Backends::Errors::AuthenticationError, "Invalid VOMS attributes! #{first_voms.inspect}"
      end

      # Password should be a DN with VOMS attrs appended and whitespaces removed.
      constructed_dn = "#{params[:client_cert_dn]}/VO=#{first_voms[:vo]}/Role=#{first_voms[:role]}/Capability=#{first_voms[:capability]}"
      username = get_username(X509Auth.escape_dn(constructed_dn))

      # TODO: remove this hack after Perun propagation scripts are updated
      if username.blank?
        # try a DN with whitespace chars removed
        username = get_username(constructed_dn.gsub(/\s+/, ''))
      end

      return nil if username.blank?

      username
    end
  end
end
