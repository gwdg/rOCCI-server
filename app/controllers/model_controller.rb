class ModelController < ApplicationController

  def index
    respond_with(Model.collection)
  end

  def show
    respond_with(Model.collection)
  end

  def create
  end

  def delete
  end
end
