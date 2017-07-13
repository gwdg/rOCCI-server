class EntityController < ApplicationController
  # GET /
  # (for legacy renderings and uri-list)
  def locations
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # GET /mixin/:parent/:term/
  # (for legacy renderings and uri-list)
  def scoped_locations
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # GET /
  # (for new renderings)
  def list
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # GET /mixin/:parent/:term/
  # (for new renderings)
  def scoped_list
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # POST /mixin/:parent/:term/
  def assign_mixin
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # POST /?action=ACTION
  def execute_all
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # POST /mixin/:parent/:term/?action=ACTION
  def scoped_execute_all
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # PUT /mixin/:parent/:term/
  def update_mixin
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # DELETE /
  def delete_all
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # DELETE /mixin/:parent/:term/
  def scoped_delete_all
    render_error :not_implemented, 'Requested functionality is not implemented'
  end
end
