Rails.application.routes.draw do
  ####################################################
  ## Occi::Core::Entity Routes (incl. Default Route)
  ####################################################
  get '/',
      to: 'multi_entity#list',
      constraints: Ext::RoutingConstraints.build(%i[non_legacy])
  get '/',
      to: 'multi_entity#locations',
      constraints: Ext::RoutingConstraints.build(%i[legacy])

  post '/',
       to: 'multi_entity#execute_all',
       constraints: Ext::RoutingConstraints.build(%i[action])

  delete '/', to: 'multi_entity#delete_all'

  root 'multi_entity#locations'

  get '/mixin/:parent/:term/',
      to: 'multi_entity#scoped_list',
      constraints: Ext::RoutingConstraints.build(%i[non_legacy])
  get '/mixin/:parent/:term/',
      to: 'multi_entity#scoped_locations',
      constraints: Ext::RoutingConstraints.build(%i[legacy])

  post '/mixin/:parent/:term/',
       to: 'multi_entity#scoped_execute_all',
       constraints: Ext::RoutingConstraints.build(%i[action])
  post '/mixin/:parent/:term/',
       to: 'multi_entity#assign_mixin',
       constraints: Ext::RoutingConstraints.build(%i[non_action])

  put '/mixin/:parent/:term/',
      to: 'multi_entity#update_mixin'

  delete '/mixin/:parent/:term/',
         to: 'multi_entity#scoped_delete_all'

  ####################################################
  ## Query Interface Routes
  ####################################################
  get '/-/', to: 'server_model#show'
  get '/.well-known/org/ogf/occi/-/', to: 'server_model#show'

  ####################################################
  ## Custom Mixin Routes
  ####################################################

  post '/-/', to: 'mixin#create'
  post '/.well-known/org/ogf/occi/-/', to: 'mixin#create'

  # put '/-/' is undefined in GFD-P-R.185
  # put '/.well-known/org/ogf/occi/-/' is undefined in GFD-P-R.185

  delete '/-/', to: 'mixin#delete'
  delete '/.well-known/org/ogf/occi/-/', to: 'mixin#delete'

  ####################################################
  ## Occi::Core::Resource Routes
  ##  - Occi::Infrastructure::Compute
  ##  - Occi::Infrastructure::Network
  ##  - Occi::Infrastructure::Storage
  ##  - Occi::InfrastructureExt::SecurityGroup
  ##  - Occi::InfrastructureExt::IPReservation
  ##
  ## and
  ##
  ## Occi::Core::Link Routes
  ##  - Occi::Infrastructure::NetworkInterface
  ##  - Occi::Infrastructure::StorageLink
  ##  - Occi::InfrastructureExt::SecurityGroupLink
  ####################################################
  get '(/link)/:entity/:id',
      to: 'resource#show'
  get '(/link)/:entity/',
      to: 'resource#list',
      constraints: Ext::RoutingConstraints.build(%i[non_legacy])
  get '(/link)/:entity/',
      to: 'resource#locations',
      constraints: Ext::RoutingConstraints.build(%i[legacy])

  post '(/link)/:entity/:id',
       to: 'resource#execute',
       constraints: Ext::RoutingConstraints.build(%i[action])
  post '(/link)/:entity/:id',
       to: 'resource#partial_update',
       constraints: Ext::RoutingConstraints.build(%i[non_action])
  post '(/link)/:entity/',
       to: 'resource#execute_all',
       constraints: Ext::RoutingConstraints.build(%i[action])
  post '(/link)/:entity/',
       to: 'resource#create',
       constraints: Ext::RoutingConstraints.build(%i[non_action])

  put '(/link)/:entity/:id',
      to: 'resource#update'
  # put '(/link)/:entity/' is undefined in GFD-P-R.185

  delete '(/link)/:entity/:id',
         to: 'resource#delete'
  delete '(/link)/:entity/',
         to: 'resource#delete_all'
end
