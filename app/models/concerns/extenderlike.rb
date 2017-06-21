module Extenderlike
  extend ActiveSupport::Concern

  #
  #
  # @param model [Occi::Core::Model] model instance to extend
  # @return [Occi::Core::Model] extended model instance (modified original)
  def populate!(model)
    model
  end
end
