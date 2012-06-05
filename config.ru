$: << 'lib'

require 'rubygems'
require 'sinatra'
require 'occi/server'

run OCCI::Server.new
