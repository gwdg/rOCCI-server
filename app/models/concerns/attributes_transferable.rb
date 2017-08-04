module AttributesTransferable
  extend ActiveSupport::Concern

  # Transfers attributes from `source` to `target` by using lambdas from
  # provided mappers. `mappers` should contain a list of hashes where attribute
  # names point to callable transformation routines (lambdas) taking exactly one
  # argument -- the `source` object.
  #
  # @param source [Object] source instance
  # @param target [Occi::Core::Entity] receiving instance
  # @param mappers [Enumerable] list of `Hash-like` mappers, values in maps MUST be callable
  def transfer_attributes!(source, target, mappers)
    raise '`mappers` must be enumerable' unless mappers.is_a? Enumerable
    raise '`target` must be Entity-like' unless target.respond_to?(:[]=) && target.respond_to?(:attributes)

    mappers.each do |mapper|
      mapper.each_pair do |k, v|
        next unless target.attributes.key?(k)
        target[k] = v.call(source)
      end
    end
  end
end
