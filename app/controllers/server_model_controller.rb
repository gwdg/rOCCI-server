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
  def show; end

  # POST /-/
  # POST /.well-known/org/ogf/occi/-/
  def mixin_create
    render_error 501, 'Requested functionality is not implemented'
  end

  # DELETE /-/
  # DELETE /.well-known/org/ogf/occi/-/
  def mixin_delete
    render_error 501, 'Requested functionality is not implemented'
  end
end
