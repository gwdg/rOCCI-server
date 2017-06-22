class EntityController < ApplicationController
  skip_before_action :validate_url_param, only: %i[locations list delete_all]

  # GET /
  # (for legacy renderings and uri-list)
  def locations; end

  # GET /mixin/:parent/:term/
  # (for legacy renderings and uri-list)
  def scoped_locations; end

  # GET /
  # (for new renderings)
  def list; end

  # GET /mixin/:parent/:term/
  # (for new renderings)
  def scoped_list; end

  # POST /mixin/:parent/:term/
  def assign_mixin
    render_error 501, 'Requested functionality is not implemented'
  end

  # POST /mixin/:parent/:term/?action=ACTION
  def scoped_execute
    render_error 501, 'Requested functionality is not implemented'
  end

  # PUT /mixin/:parent/:term/
  def update_mixin
    render_error 501, 'Requested functionality is not implemented'
  end

  # DELETE /
  def delete_all
    render_error 501, 'Requested functionality is not implemented'
  end

  # DELETE /mixin/:parent/:term/
  def scoped_delete_all
    render_error 501, 'Requested functionality is not implemented'
  end

  protected

  def acceptable_url_params
    %w[os_tpl resource_tpl availability_zone]
  end

  def url_param_key
    :parent
  end
end
