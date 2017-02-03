# Controller class handling all networkinterface-related requests.
# Implements retrieval, creation and deletion of networkinterface instances.
class NetworkinterfaceController < ApplicationController
  # GET /link/networkinterface/
  def index
    if INDEX_LINK_FORMATS.include?(request.format)
      @nis = backend_instance.compute_get_network_list_ids
      @nis.map! { |c| "#{server_url}/link/networkinterface/#{c}" }
      options = { flag: :links_only }
    else
      @nis = Occi::Collection.new
      @nis.links = backend_instance.compute_get_network_list
      update_mixins_in_coll(@nis)
      options = {}
    end

    respond_with(@nis, options)
  end

  # GET /link/networkinterface/:id
  def show
    @networkinterface = Occi::Collection.new
    @networkinterface << backend_instance.compute_get_network(params[:id])

    unless @networkinterface.empty?
      update_mixins_in_coll(@networkinterface)
      respond_with(@networkinterface)
    else
      respond_with(Occi::Collection.new, status: 404)
    end
  end

  # POST /link/networkinterface/
  def create
    networkinterface = request_occi_collection(Occi::Core::Link).links.first
    networkinterface_location = backend_instance.compute_attach_network(networkinterface)

    respond_with("#{server_url}/link/networkinterface/#{networkinterface_location}", status: 201, flag: :link_only)
  end

  # DELETE /link/networkinterface/:id
  def delete
    result = backend_instance.compute_detach_network(params[:id])

    if result
      respond_with(Occi::Collection.new)
    else
      respond_with(Occi::Collection.new, status: 304)
    end
  end
end
