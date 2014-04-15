# Controller class handling all model-related requests.
# Implements listing of resources, retrieval of the model
# and creation/deletion of mixins.
class OcciModelController < ApplicationController
  # GET /
  def index
    if INDEX_LINK_FORMATS.include?(request.format)
      @resources = []

      @resources.concat(backend_instance.compute_list_ids.map { |c| "#{server_url}/compute/#{c}" })
      @resources.concat(backend_instance.network_list_ids.map { |n| "#{server_url}/network/#{n}" })
      @resources.concat(backend_instance.storage_list_ids.map { |s| "#{server_url}/storage/#{s}" })
      options = { flag: :links_only }
    else
      @resources = Occi::Collection.new

      @resources.resources.merge backend_instance.compute_list
      @resources.resources.merge backend_instance.network_list
      @resources.resources.merge backend_instance.storage_list
      options = {}
    end

    respond_with(@resources, options)
  end

  # GET /-/
  # GET /.well-known/org/ogf/occi/-/
  def show
    @model = OcciModel.get(backend_instance, request_occi_collection)
    respond_with(@model)
  end

  # POST /-/
  # POST /.well-known/org/ogf/occi/-/
  def create
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end

  # DELETE /-/
  # DELETE /.well-known/org/ogf/occi/-/
  def delete
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end
end
