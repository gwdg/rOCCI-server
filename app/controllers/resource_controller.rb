class ResourceController < ApplicationController
  # GET /:resource/
  # (for legacy renderings and uri-list)
  def locations; end

  # GET /:resource/
  # (for new renderings)
  def list; end

  # GET /:resource/:id
  def show; end

  # POST /:resource/
  def create; end

  # POST /:resource/:id?action=ACTION
  def execute; end

  # PUT /:resource/:id
  def update; end

  # POST /:resource/:id
  def partial_update; end

  # DELETE /:resource/:id
  def delete; end

  # DELETE /:resource/
  def delete_all; end

  protected

  def acceptable_url_params
    %w[compute network storage]
  end

  def url_param_key
    :resource
  end
end
