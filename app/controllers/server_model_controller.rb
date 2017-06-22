class ServerModelController < ApplicationController
  skip_before_action :validate_url_param

  # GET /-/
  # GET /.well-known/org/ogf/occi/-/
  def show
    respond_with server_model
  end
end
