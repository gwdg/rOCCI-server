class ServerModelController < ApplicationController
  # GET /
  # (for legacy renderings and uri-list)
  def locations; end

  # GET /
  # (for new renderings)
  def list; end

  # GET /-/
  # GET /.well-known/org/ogf/occi/-/
  def show; end

  # POST /-/
  # POST /.well-known/org/ogf/occi/-/
  def mixin_create; end

  # DELETE /-/
  # DELETE /.well-known/org/ogf/occi/-/
  def mixin_delete; end
end
