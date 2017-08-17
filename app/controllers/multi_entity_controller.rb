class MultiEntityController < ApplicationController
  include LocationsTransformable

  # Allowed subtypes
  ALLOWED_SUBTYPES = %w[entity resource link].freeze

  # Known mixin parents (being depended on)
  MIXIN_PARENTS = %w[os_tpl resource_tpl availability_zone region floatingippool].freeze

  before_action :validate_provided_format!, only: %i[assign_mixin scoped_execute_all update_mixin]
  before_action :parent_exists!, except: %i[locations list delete_all blackhole]

  # GET /(:entity/)
  # (for legacy renderings and uri-list)
  def locations
    locations = Occi::Core::Locations.new

    all(params[:entity]).each do |bt|
      bt_ids = backend_proxy_for(bt).identifiers
      locations_from(bt_ids, bt, locations)
    end
    return if locations.empty?

    respond_with locations
  end

  # GET /mixin/:parent/:term/
  # (for legacy renderings and uri-list)
  def scoped_locations
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # GET /(:entity/)
  # (for new renderings)
  def list
    collection = empty_collection
    all(params[:entity]).each do |bt|
      bt_coll = backend_proxy_for(bt).list
      collection.entities.merge bt_coll.entities
    end

    return if collection.only_categories?
    collection.valid!

    respond_with collection
  end

  # GET /mixin/:parent/:term/
  # (for new renderings)
  def scoped_list
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # POST /mixin/:parent/:term/
  def assign_mixin
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # POST /mixin/:parent/:term/?action=ACTION
  def scoped_execute_all
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # PUT /mixin/:parent/:term/
  def update_mixin
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # DELETE /(:entity/)
  def delete_all
    all(params[:entity]).each { |bt| backend_proxy_for(bt).delete_all }
  end

  # DELETE /mixin/:parent/:term/
  def scoped_delete_all
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  # POST /(:entity/)
  def blackhole
    render_error :not_implemented, 'Requested functionality is not implemented'
  end

  protected

  # Returns a list of known backend subtypes.
  #
  # @param type [String] type of backend subtype
  # @return [Enumerable] list of available backend subtypes
  def all(type)
    type ||= ALLOWED_SUBTYPES.first
    unless ALLOWED_SUBTYPES.include?(type)
      raise Errors::BackendForbiddenError, 'Attempting to access forbidden backend subtype'
    end
    BackendProxy.send("backend_#{type}_subtypes")
  end

  # Validates URL fragment (Rails parameter `:parent`) against a list of known
  # parent mixins. This PARTIALLY implementes work with mixin-defined collections.
  def parent_exists!
    return if valid_mixin_parent?(params[:parent])
    render_error :not_found, 'Requested collection could not be found'
  end

  # Checks for known mixin parent.
  #
  # @param term [String] mixin parent to check
  # @return [TrueClass] if parent is known
  # @return [FalseClass] if parent is NOT known
  def valid_mixin_parent?(term)
    MIXIN_PARENTS.include? term
  end
end
