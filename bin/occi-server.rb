#!/usr/bin/env ruby

# -------------------------------------------------------------------------- #
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
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

#TODO write an script to start rocci with amqp or http frontend

require 'rubygems'
require 'occi/helper/occi_server_options'
require 'occi/server'
require 'rack'

options = OCCI::Helper::OcciServerOptions.new
options._parse ARGV

server = OCCI::Server.new().start(options.frontend, true)

if options.frontend == 'http'
  #TODO start inside Passenger
  Rack::Server.new(:app => server, :Port => 9292, :server => 'webrick').start
end






