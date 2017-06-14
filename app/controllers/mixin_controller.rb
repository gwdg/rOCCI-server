class MixinController < ApplicationController
  # GET /mixin/*mxn_path/
  # (for legacy renderings and uri-list)
  def scoped_locations; end

  # GET /mixin/*mxn_path/
  # (for new renderings)
  def scoped_list; end

  # POST /mixin/*mxn_path/
  def assign; end

  # POST /mixin/*mxn_path/?action=ACTION
  def scoped_execute; end

  # PUT /mixin/*mxn_path/:id
  def update; end

  # DELETE /mixin/*mxn_path/
  def scoped_delete_all; end
end
