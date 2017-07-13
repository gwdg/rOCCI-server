class LinkController < ApplicationController
  include ParserAccessible

  before_action :link_exists!, only: %i[show execute update partial_update delete]

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
  def execute
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # POST /link/:link/?action=ACTION
  def execute_all
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # PUT /link/:link/:id
  def update
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # POST /link/:link/:id
  def partial_update
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # DELETE /link/:link/:id
  def delete; end

  # DELETE /link/:link/
  delegate :delete_all, to: :default_backend_proxy

  protected

  # Returns default backend instance for the given controller.
  #
  # @return [Entitylike, Extenderlike] subtype instance
  def default_backend_proxy
    backend_proxy_for params[:link]
  end

  def link_exists!
    return if default_backend_proxy.exists?(params[:id])
    render_error :not_found, 'Requested link could not be found'
  end

  def parsed_links
    links = parser_wrapper { request_parser.links(request.raw_post, request.headers) }
    validate_entities! links
  end
end
