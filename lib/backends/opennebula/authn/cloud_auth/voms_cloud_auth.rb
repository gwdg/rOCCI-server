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

    # Performs authentication for VOMS-based user credentials supplied
    # in the `params` argument. Returns `nil` on failure or username
    # on success. In case of multiple VOMS attribute sets, the first
    # successful match is accepted (i.e., the most generic one).
    #
    # @param params [Hash] hash with authN parameters
    # @return [String, NilClass] username of the authenticated user
    def do_auth(params = {})
      fail Backends::Errors::AuthenticationError, 'Credentials for X.509 not set!' unless params && params[:client_cert_dn]
      fail Backends::Errors::AuthenticationError, 'Attributes for VOMS not set!' unless params[:client_cert_voms_attrs] && params[:client_cert_voms_attrs].first

      # loop through available credentials and find a match in OpenNebula
      username = nil
      params[:client_cert_voms_attrs].each do |voms_attr_set|
        if voms_attr_set[:vo].blank? || voms_attr_set[:role].blank? || voms_attr_set[:capability].blank?
          fail Backends::Errors::AuthenticationError, "Invalid VOMS attributes! #{voms_attr_set.inspect}"
        end

        # password should be a DN with VOMS attrs appended and whitespaces removed
        constructed_dn = "#{params[:client_cert_dn]}/VO=#{voms_attr_set[:vo]}/Role=#{voms_attr_set[:role]}/Capability=#{voms_attr_set[:capability]}"

        # try an escaped DN or a DN with whitespace chars removed
        # TODO: remove this hack after Perun propagation scripts are updated
        username = get_username(X509Auth.escape_dn(constructed_dn)) || get_username(constructed_dn.gsub(/\s+/, ''))
        username = nil if username.blank?

        # found a user with matching credentials, stop looking
        # TODO: is this an acceptable approach?
        break if username
      end

      username.blank? ? nil : username
    end

  end
end
