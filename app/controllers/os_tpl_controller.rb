# Controller class handling all os_tpl-related requests.
# Implements listing and triggering actions on mixin-tagged instances.
class OsTplController < ApplicationController
  # GET /mixin/os_tpl/:term*/
  def index
    # TODO: work with :term*
    mixins = Occi::Core::Mixins.new << Occi::Infrastructure::OsTpl.mixin

    if INDEX_LINK_FORMATS.include?(request.format)
      @computes = backend_instance.compute_list_ids(mixins)
      @computes.map! { |c| "#{server_url}/compute/#{c}" }
      options = { flag: :links_only }
    else
      @computes = Occi::Collection.new
      @computes.resources = backend_instance.compute_list(mixins)
      update_mixins_in_coll(@computes)
      options = {}
    end

    respond_with(@computes, options)
  end

  # POST /mixin/os_tpl/:term*/?action=:action
  def trigger
    # TODO: impl
    collection = Occi::Collection.new
    respond_with(collection, status: 501)
  end
end
