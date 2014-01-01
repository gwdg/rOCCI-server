class StoragelinkController < ApplicationController

  # GET /link/storagelink/:id
  def show
    @storagelink = backend_instance.compute_get_storage(params[:id])

    if @storagelink
      respond_with(@storagelink)
    else
      respond_with(Occi::Collection.new, status: 404)
    end
  end

  # POST /link/storagelink/
  def create
    storagelink = request_occi_collection.links.first
    storagelink_location = backend_instance.compute_attach_storage(storagelink)

    respond_with("/link/storagelink/#{storagelink_location}", status: 201, flag: :link_only)
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
