class MixinController < ApplicationController
  # POST /-/
  # POST /.well-known/org/ogf/occi/-/
  def create
    render_error 501, 'Requested functionality is not implemented'
  end

  # DELETE /-/
  # DELETE /.well-known/org/ogf/occi/-/
  def delete
    render_error 501, 'Requested functionality is not implemented'
  end
end
