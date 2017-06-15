class ServerModelController < ApplicationController
  skip_before_action :validate_url_param

  # GET /
  # (for legacy renderings and uri-list)
  def locations; end

  # GET /
  # (for new renderings)
  def list; end

  # GET /-/
  # GET /.well-known/org/ogf/occi/-/
  def show
    model = ::Occi::InfrastructureExt::Model.new
    model.load_core!
    model.load_infrastructure!
    model.load_infrastructure_ext!

    respond_with model
  end

  # POST /-/
  # POST /.well-known/org/ogf/occi/-/
  def mixin_create; end

  # DELETE /-/
  # DELETE /.well-known/org/ogf/occi/-/
  def mixin_delete; end
end
