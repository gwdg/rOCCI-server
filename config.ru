$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'rubygems'
require 'sinatra'
require 'occi/server'

run OCCI::Server.new().start('http')

