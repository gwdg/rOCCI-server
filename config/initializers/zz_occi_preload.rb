# Trigger preloads on rOCCI-core libs, to save time during request processing and avoid potential
# loading issues at runtime.

# Before doing this, `Yell` must already be initialized! Hence the `zz_` prefix.

silence_warnings do
  Occi::Core::Category
  Occi::Core::Entity
  Occi::Core::Locations
  Occi::Core::ActionInstance
  Occi::Core::Model
end

# Initialize ext helpers
require 'occi/infrastructure_ext/monkey_island'
