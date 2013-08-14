ROCCIServer::Application.routes.draw do
  
  get 'network/', to: 'network#index', as: 'network'
  get 'storage/', to: 'storage#index', as: 'storage'
  get 'compute/', to: 'compute#index', as: 'compute'

  #root 'welcome#index'
end
