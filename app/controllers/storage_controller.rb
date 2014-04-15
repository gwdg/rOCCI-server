# Controller class handling all storage-related requests.
# Implements listing, retrieval, creation, deletion and
# triggering actions on storage instances.
class StorageController < ApplicationController
  # GET /storage/
  def index
    if INDEX_LINK_FORMATS.include?(request.format)
      @storages = backend_instance.storage_list_ids
      @storages.map! { |c| "#{server_url}/storage/#{c}" }
      options = { flag: :links_only }
    else
      @storages = Occi::Collection.new
      @storages.resources = backend_instance.storage_list
      update_mixins_in_coll(@storages)
      options = {}
    end

    respond_with(@storages, options)
  end

  # GET /storage/:id
  def show
    @storage = Occi::Collection.new
    @storage << backend_instance.storage_get(params[:id])

    unless @storage.empty?
      update_mixins_in_coll(@storage)
      respond_with(@storage)
    else
      respond_with(Occi::Collection.new, status: 404)
    end
  end

  # POST /storage/
  def create
    storage = request_occi_collection.resources.first
    storage_location = backend_instance.storage_create(storage)

    respond_with("#{server_url}/storage/#{storage_location}", status: 201, flag: :link_only)
  end

  # POST /storage/?action=:action
  # POST /storage/:id?action=:action
  def trigger
    ai = request_occi_collection(Occi::Core::ActionInstance).action
    check_ai!(ai, request.query_string)

    if params[:id]
      result = backend_instance.storage_trigger_action(params[:id], ai)
    else
      result = backend_instance.storage_trigger_action_on_all(ai)
    end

    if result
      respond_with(Occi::Collection.new)
    else
      respond_with(Occi::Collection.new, status: 304)
    end
  end

  # POST /storage/:id
  def partial_update
    # TODO: impl
    respond_with(Occi::Collection.new, status: 501)
  end

  # PUT /storage/:id
  def update
    storage = request_occi_collection.resources.first
    storage.id = params[:id] if storage
    result = backend_instance.storage_update(storage)

    if result
      storage = Occi::Collection.new
      storage << backend_instance.storage_get(params[:id])

      unless storage.empty?
        update_mixins_in_coll(storage)
        respond_with(storage)
      else
        respond_with(Occi::Collection.new, status: 404)
      end
    else
      respond_with(Occi::Collection.new, status: 304)
    end
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
