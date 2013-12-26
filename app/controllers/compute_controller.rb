class ComputeController < ApplicationController

  # GET /compute/
  def index
    if request.format == "text/uri-list"
      @computes = backend_instance.compute_list_ids
      @computes.map! { |c| "/compute/#{c}" }
    else
      @computes = backend_instance.compute_list
    end

    respond_with(@computes)
  end

  # GET /compute/:id
  def show
    @compute = backend_instance.compute_get(params[:id])

    if @compute
      respond_with(@compute)
    else
      respond_with(Occi::Collection.new, status: 404)
    end
  end

  # POST /compute/
  def create
    compute = request_occi_collection.resources.first
    compute_location = backend_instance.compute_create(compute)

    respond_with("/compute/#{compute_location}", status: 201, flag: :link_only)
  end

  # POST /compute/?action=:action
  # POST /compute/:id?action=:action
  def trigger
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end

  # POST /compute/:id
  # PUT /compute/:id
  def update
    compute = request_occi_collection.resources.first
    compute_upd = backend_instance.compute_update(compute)

    respond_with(Occi::Collection.new)
  end

  # DELETE /compute/
  # DELETE /compute/:id
  def delete
    if params[:id]
      result = backend_instance.compute_delete(params[:id])
    else
      result = backend_instance.compute_delete_all
    end

    if result
      respond_with(Occi::Collection.new)
    else
      respond_with(Occi::Collection.new, status: 304)
    end
  end
end
