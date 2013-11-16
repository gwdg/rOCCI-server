class MixinController < ApplicationController

  # GET /mixin/:term*/
  def index
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end

  # POST /mixin/:term*/?action=:action
  def trigger
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end

  # POST /mixin/:term*/
  def assign
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end

  # PUT /mixin/:term*/
  def update
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end

  # DELETE /mixin/:term*/
  def delete
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end
end
