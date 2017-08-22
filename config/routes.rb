Rails.application.routes.draw do
  ####################################################
  ## Occi::Core::Entity Routes (incl. Default Route)
  ####################################################
  get '/', to: 'multi_entity#list',
           constraints: Ext::RoutingConstraints.build(%i[non_legacy])
  get '/', to: 'multi_entity#locations',
           constraints: Ext::RoutingConstraints.build(%i[legacy])

  post '/', to: 'multi_entity#blackhole'

  # put '/:entity/' is undefined in GFD-P-R.185

  delete '/', to: 'multi_entity#delete_all'

  get '/:entity/', to: 'multi_entity#list',
                   constraints: Ext::RoutingConstraints.build(%i[abstract non_legacy])
  get '/:entity/', to: 'multi_entity#locations',
                   constraints: Ext::RoutingConstraints.build(%i[abstract legacy])

  post '/:entity/', to: 'multi_entity#blackhole',
                    constraints: Ext::RoutingConstraints.build(%i[abstract])

  # put '/:entity/' is undefined in GFD-P-R.185

  delete '/:entity/', to: 'multi_entity#delete_all',
                      constraints: Ext::RoutingConstraints.build(%i[abstract])

  get '/mixin/:parent/:term/', to: 'multi_entity#scoped_list',
                               constraints: Ext::RoutingConstraints.build(%i[non_legacy])
  get '/mixin/:parent/:term/', to: 'multi_entity#scoped_locations',
                               constraints: Ext::RoutingConstraints.build(%i[legacy])

  post '/mixin/:parent/:term/', to: 'multi_entity#scoped_execute_all',
                                constraints: Ext::RoutingConstraints.build(%i[action])
  post '/mixin/:parent/:term/', to: 'multi_entity#assign_mixin',
                                constraints: Ext::RoutingConstraints.build(%i[non_action])

  put '/mixin/:parent/:term/', to: 'multi_entity#update_mixin'

  delete '/mixin/:parent/:term/', to: 'multi_entity#scoped_delete_all'

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
  get '/:entity/:id', to: 'entity#show',
                      constraints: Ext::RoutingConstraints.build(%i[concrete])
  get '/:entity/', to: 'entity#list',
                   constraints: Ext::RoutingConstraints.build(%i[concrete non_legacy])
  get '/:entity/', to: 'entity#locations',
                   constraints: Ext::RoutingConstraints.build(%i[concrete legacy])

  post '/:entity/:id', to: 'entity#execute',
                       constraints: Ext::RoutingConstraints.build(%i[concrete action])
  post '/:entity/:id', to: 'entity#partial_update',
                       constraints: Ext::RoutingConstraints.build(%i[concrete non_action])
  post '/:entity/', to: 'entity#execute_all',
                    constraints: Ext::RoutingConstraints.build(%i[concrete action])
  post '/:entity/', to: 'entity#create',
                    constraints: Ext::RoutingConstraints.build(%i[concrete non_action])

  put '/:entity/:id', to: 'entity#update',
                      constraints: Ext::RoutingConstraints.build(%i[concrete])
  # put '/:entity/' is undefined in GFD-P-R.185

  delete '/:entity/:id', to: 'entity#delete',
                         constraints: Ext::RoutingConstraints.build(%i[concrete])
  delete '/:entity/', to: 'entity#delete_all',
                      constraints: Ext::RoutingConstraints.build(%i[concrete])
end
