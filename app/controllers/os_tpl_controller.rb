class OsTplController < ApplicationController

  # GET /mixin/os_tpl/:term*/
  def index
    # TODO: work with :term*
    mixins = Occi::Core::Mixins.new << Occi::Infrastructure::OsTpl.mixin

    @computes = Occi::Collection.new
    @computes.resources = backend_instance.compute_list(mixins)
    respond_with(@computes)
  end

  # POST /mixin/os_tpl/:term*/?action=:action
  def trigger
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end
end
