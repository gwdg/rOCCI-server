class ServerModelController < ApplicationController
  # GET /-/
  # GET /.well-known/org/ogf/occi/-/
  def show
    # TODO: filtering via headers?
    respond_with server_model
  end
end
