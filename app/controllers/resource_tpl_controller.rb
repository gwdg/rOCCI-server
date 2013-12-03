class ResourceTplController < ApplicationController

  # GET /mixin/resource_tpl/:term*/
  def index
    # TODO: work with :term*
    mixins = Occi::Core::Mixins.new << Occi::Infrastructure::ResourceTpl.mixin
    @computes = backend_instance.compute_list(mixins)
    respond_with(@computes)
  end

  # POST /mixin/resource_tpl/:term*/?action=:action
  def trigger
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end
end
