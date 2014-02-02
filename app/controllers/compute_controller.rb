class ComputeController < ApplicationController

  # GET /compute/
  def index
    if request.format == "text/uri-list"
      @computes = backend_instance.compute_list_ids
      @computes.map! { |c| "#{server_url}/compute/#{c}" }
    else
      @computes = Occi::Collection.new
      @computes.resources = backend_instance.compute_list
    end

    respond_with(@computes)
  end

  # GET /compute/:id
  def show
    @compute = Occi::Collection.new
    @compute << backend_instance.compute_get(params[:id])

    unless @compute.empty?
      respond_with(@compute)
    else
      respond_with(Occi::Collection.new, status: 404)
    end
  end

  # POST /compute/
  def create
    compute = request_occi_collection.resources.first
    compute_location = backend_instance.compute_create(compute)

    respond_with("#{server_url}/compute/#{compute_location}", status: 201, flag: :link_only)
  end

  # POST /compute/?action=:action
  # POST /compute/:id?action=:action
  def trigger
    ai = request_occi_collection(Occi::Core::ActionInstance).action
    check_ai!(ai, request.query_string)

    if params[:id]
      result = backend_instance.compute_trigger_action(params[:id], ai)
    else
      result = backend_instance.compute_trigger_action_on_all(ai)
    end

    if result
      respond_with(Occi::Collection.new)
    else
      respond_with(Occi::Collection.new, status: 304)
    end
  end

  # POST /compute/:id
  def partial_update
    # TODO: impl
    respond_with(Occi::Collection.new, status: 501)
  end

  # PUT /compute/:id
  def update
    compute = request_occi_collection.resources.first
    compute.id = params[:id] if compute
    result = backend_instance.compute_update(compute)

    if result
      compute = Occi::Collection.new
      compute << backend_instance.compute_get(params[:id])

      unless compute.empty?
        respond_with(compute)
      else
        respond_with(Occi::Collection.new, status: 404)
      end
    else
      respond_with(Occi::Collection.new, status: 304)
    end
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
