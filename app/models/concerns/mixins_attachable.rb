module MixinsAttachable
  extend ActiveSupport::Concern

  # :nodoc:
  def attach_optional_mixin!(entity, term, type)
    mxn = server_model.send("find_#{type}s").detect { |m| m.term == term }
    return unless mxn
    entity << mxn
  end
end
