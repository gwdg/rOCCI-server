class NetworkController < ApplicationController

  # GET /network/
  def index
    if request.format == "text/uri-list"
      @networks = backend_instance.network_list_ids
      @networks.map! { |c| "/network/#{c}" }
    else
      @networks = backend_instance.network_list
    end

    respond_with(@networks)
  end

  # GET /network/:id
  def show
    @network = backend_instance.network_get(params[:id])

    if @network
      respond_with(@network)
    else
      respond_with(Occi::Collection.new, status: 404)
    end
  end

  # POST /network/
  def create
    network = request_occi_collection.resources.first
    network_location = backend_instance.network_create(network)

    respond_with("/network/#{network_location}", status: 201, flag: :link_only)
  end

  # POST /network/?action=:action
  # POST /network/:id?action=:action
  def trigger
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end

  # POST /network/:id
  # PUT /network/:id
  def update
    network = request_occi_collection.resources.first
    network_upd = backend_instance.network_update(network)

    respond_with(Occi::Collection.new)
  end

  # DELETE /network/
  # DELETE /network/:id
  def delete
    if params[:id]
      result = backend_instance.network_delete(params[:id])
    else
      result = backend_instance.network_delete_all
    end

    if result
      respond_with(Occi::Collection.new)
    else
      respond_with(Occi::Collection.new, status: 304)
    end
  end
end
