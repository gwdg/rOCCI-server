class OcciModelController < ApplicationController

  def index
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
