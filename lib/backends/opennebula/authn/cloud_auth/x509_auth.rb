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
  # X509 authentication class.
  class X509Auth
    def self.escape_dn(dn)
      dn.gsub(/\s/) { |s| '\\' + s[0].ord.to_s(16) }
    end

    def self.unescape_dn(dn)
      dn.gsub(/\\[0-9a-f]{2}/) { |s| s[1, 2].to_i(16).chr }
    end
  end
end
