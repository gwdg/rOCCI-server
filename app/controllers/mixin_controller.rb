# Controller class handling all mixin-related requests.
# Implements listing, assignment, creation, deletion and
# triggering actions on mixin-tagged instances.
#
# `os_tpl` and `resource_tpl` mixins are a special case and
# are handled separately. See OsTplController and ResourceTplController.
#
# TODO: Not yet implemented! Returns HTTP 501 for all requests!
class MixinController < ApplicationController
  # GET /mixin/:term*/
  def index
    # TODO: impl
    @resources = Occi::Collection.new
    respond_with(@resources, status: 501)
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
