class MixinController < ApplicationController
  # GET /mixin/:parent/:term/
  # (for legacy renderings and uri-list)
  def scoped_locations; end

  # GET /mixin/:parent/:term/
  # (for new renderings)
  def scoped_list; end

  # POST /mixin/:parent/:term/
  def assign
    render text: 'Requested functionality is not implemented', status: 501
  end

  # POST /mixin/:parent/:term/?action=ACTION
  def scoped_execute; end

  # PUT /mixin/:parent/:term/
  def update
    render text: 'Requested functionality is not implemented', status: 501
  end

  # DELETE /mixin/:parent/:term/
  def scoped_delete_all; end

  protected

  def acceptable_url_params
    %w[os_tpl resource_tpl availability_zone]
  end

  def url_param_key
    :parent
  end
end
