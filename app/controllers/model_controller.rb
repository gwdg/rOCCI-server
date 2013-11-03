class ModelController < ApplicationController

  def index
  end

  def show
    model = Model.get_filtered(request_occi_collection)
    respond_with(model)
  end

  def create
  end

  def delete
  end

end
