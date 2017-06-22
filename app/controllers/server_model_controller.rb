class ServerModelController < ApplicationController
  # GET /-/
  # GET /.well-known/org/ogf/occi/-/
  def show
    respond_with server_model
  end
end
