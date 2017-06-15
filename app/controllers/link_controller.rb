class LinkController < ApplicationController
  # GET /link/:link/
  # (for legacy renderings and uri-list)
  def locations; end

  # GET /link/:link/
  # (for new renderings)
  def list; end

  # GET /link/:link/:id
  def show; end

  # POST /link/:link/
  def create; end

  # POST /link/:link/:id?action=ACTION
  def execute; end

  # PUT /link/:link/:id
  def update; end

  # POST /link/:link/:id
  def partial_update; end

  # DELETE /link/:link/:id
  def delete; end

  # DELETE /link/:link/
  def delete_all; end

  protected

  def acceptable_url_params
    %w[networkinterface storagelink]
  end

  def url_param_key
    :link
  end
end
