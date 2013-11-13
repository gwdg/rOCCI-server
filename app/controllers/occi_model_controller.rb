class OcciModelController < ApplicationController

  def index
    resources = Occi::Core::Resources.new

    resources.merge Backend.instance.compute_get_all
    resources.merge Backend.instance.network_get_all
    resources.merge Backend.instance.storage_get_all

    respond_with(resources)
  end

  def show
    model = OcciModel.get(request_occi_collection)
    respond_with(model)
  end

  def create
  end

  def delete
  end

end
