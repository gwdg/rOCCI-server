# Controller class handling all compute-related requests.
# Implements listing, retrieval, creation, deletion and
# triggering actions on compute instances.
class ComputeController < ApplicationController
  # GET /compute/
  def index
    if INDEX_LINK_FORMATS.include?(request.format)
      @computes = backend_instance.compute_list_ids
      @computes.map! { |c| "#{server_url}/compute/#{c}" }
      options = { flag: :links_only }
    else
      @computes = Occi::Collection.new
      @computes.resources = backend_instance.compute_list
      update_mixins_in_coll(@computes)
      options = {}
    end

    respond_with(@computes, options)
  end

  # GET /compute/:id
  def show
    @compute = Occi::Collection.new
    @compute << backend_instance.compute_get(params[:id])

    if @compute.empty?
      respond_with(Occi::Collection.new, status: 404)
    else
      update_mixins_in_coll(@compute)
      respond_with(@compute)
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

    result = if params[:id]
               backend_instance.compute_trigger_action(params[:id], ai)
             else
               backend_instance.compute_trigger_action_on_all(ai)
             end
    coll = Occi::Collection.new
    coll.mixins = result if result.kind_of? Occi::Core::Mixins
    result ? respond_with(coll) : respond_with(coll, status: 304)
  end

  # POST /compute/:id
  def partial_update
    mixins = request_occi_collection(nil, true).mixins
    result = backend_instance.compute_partial_update(params[:id], nil, mixins)

    unless result
      respond_with(Occi::Collection.new, status: 304)
      return
    end

    compute = Occi::Collection.new
    compute << backend_instance.compute_get(params[:id])

    if compute.empty?
      respond_with(Occi::Collection.new, status: 404)
    else
      update_mixins_in_coll(compute)
      respond_with(compute)
    end
  end

  # PUT /compute/:id
  def update
    compute = request_occi_collection.resources.first
    compute.id = params[:id] if compute
    result = backend_instance.compute_update(compute)

    unless result
      respond_with(Occi::Collection.new, status: 304)
      return
    end

    compute = Occi::Collection.new
    compute << backend_instance.compute_get(params[:id])

    if compute.empty?
      respond_with(Occi::Collection.new, status: 404)
    else
      update_mixins_in_coll(compute)
      respond_with(compute)
    end
  end

  # DELETE /compute/
  # DELETE /compute/:id
  def delete
    result = if params[:id]
               backend_instance.compute_delete(params[:id])
             else
               backend_instance.compute_delete_all
             end

    result ? respond_with(Occi::Collection.new) : respond_with(Occi::Collection.new, status: 304)
  end
end
