class StorageController < ApplicationController

  # GET /storage/
  def index
    storages = backend_instance.storage_list
    respond_with(storages)
  end

  # GET /storage/:id
  def show
    storage = backend_instance.storage_get(params[:id])

    if storage
      respond_with(storage)
    else
      respond_with(Occi::Collection.new, status: 404)
    end
  end

  # POST /storage/
  def create
    storage = request_occi_collection.resources.first
    storage_location = backend_instance.storage_create(storage)

    respond_with("/storage/#{storage_location}", status: 201, flag: :link_only)
  end

  # POST /storage/?action=:action
  # POST /storage/:id?action=:action
  def trigger
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end

  # POST /storage/:id
  # PUT /storage/:id
  def update
    storage = request_occi_collection.resources.first
    storage_upd = backend_instance.storage_update(storage)

    respond_with(Occi::Collection.new)
  end

  # DELETE /storage/
  # DELETE /storage/:id
  def delete
    if params[:id]
      result = backend_instance.storage_delete(params[:id])
    else
      result = backend_instance.storage_delete_all
    end

    if result
      respond_with(Occi::Collection.new)
    else
      respond_with(Occi::Collection.new, status: 304)
    end
  end
end
