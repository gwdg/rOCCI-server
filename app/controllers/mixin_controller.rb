class MixinController < ApplicationController
  before_action :validate_provided_format!, only: %i[create]

  # POST /-/
  # POST /.well-known/org/ogf/occi/-/
  def create
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # DELETE /-/
  # DELETE /.well-known/org/ogf/occi/-/
  def delete
    render_error :not_implemented, 'Requested functionality is not implemented'
  end
end
