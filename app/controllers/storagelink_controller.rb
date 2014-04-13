# Controller class handling all storagelink-related requests.
# Implements retrieval, creation and deletion of storagelink instances.
class StoragelinkController < ApplicationController
  # GET /link/storagelink/:id
  def show
    @storagelink = Occi::Collection.new
    @storagelink << backend_instance.compute_get_storage(params[:id])

    unless @storagelink.empty?
      update_mixins_in_coll(@storagelink)
      respond_with(@storagelink)
    else
      respond_with(Occi::Collection.new, status: 404)
    end
  end

  # POST /link/storagelink/
  def create
    storagelink = request_occi_collection(Occi::Core::Link).links.first
    storagelink_location = backend_instance.compute_attach_storage(storagelink)

    respond_with("#{server_url}/link/storagelink/#{storagelink_location}", status: 201, flag: :link_only)
  end

  # DELETE /link/storagelink/:id
  def delete
    result = backend_instance.compute_detach_storage(params[:id])

    if result
      respond_with(Occi::Collection.new)
    else
      respond_with(Occi::Collection.new, status: 304)
    end
  end
end
