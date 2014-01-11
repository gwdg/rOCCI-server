class OcciModelController < ApplicationController

  # GET /
  def index
    if request.format == "text/uri-list"
      @resources = []

      @resources.concat(backend_instance.compute_list_ids.map { |c| "/compute/#{c}" })
      @resources.concat(backend_instance.network_list_ids.map { |n| "/network/#{n}" })
      @resources.concat(backend_instance.storage_list_ids.map { |s| "/storage/#{s}" })
    else
      @resources = Occi::Collection.new

      @resources.resources.merge backend_instance.compute_list
      @resources.resources.merge backend_instance.network_list
      @resources.resources.merge backend_instance.storage_list
    end

    respond_with(@resources)
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
