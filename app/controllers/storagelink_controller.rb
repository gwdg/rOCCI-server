class StoragelinkController < ApplicationController

  # GET /link/storagelink/:id
  def show
    # TODO: impl
    @storagelink = Occi::Infrastructure::Storagelink.new
    respond_with(@storagelink, status: 501)
  end

  # POST /link/storagelink/
  def create
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end

  # DELETE /link/storagelink/:id
  def delete
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end
end
