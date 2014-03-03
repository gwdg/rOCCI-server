require 'spec_helper'

describe 'routing to compute' do

  context 'GET' do
    it 'routes /compute/:id to compute#show' do
      expect(get: '/compute/54fdaa-6a4df65adf-ad6f4adf6').to route_to(
        controller: 'compute',
        action: 'show',
        id: '54fdaa-6a4df65adf-ad6f4adf6'
      )
    end

    it 'routes /compute/ to compute#index' do
      expect(get: '/compute/').to route_to(
        controller: 'compute',
        action: 'index'
      )
    end
  end

  context 'POST' do
    it 'routes /compute/ to compute#create' do
      expect(post: '/compute/').to route_to(
        controller: 'compute',
        action: 'create'
      )
    end

    it 'routes /compute/:id to compute#update' do
      expect(post: '/compute/654fad6f-adf465df4-a6df4ad6f').to route_to(
        controller: 'compute',
        action: 'partial_update',
        id: '654fad6f-adf465df4-a6df4ad6f'
      )
    end

    it 'routes /compute/?action=:action to compute#trigger'# do
    #   expect(post: '/compute/?action=stop').to route_to(
    #     controller: 'compute',
    #     action: 'trigger'
    #   )
    # end

    it 'routes /compute/:id?action=:action to compute#trigger'# do
    #   expect(post: '/compute/654fad6f-adf465df4-a6df4ad6f?action=stop').to route_to(
    #     controller: 'compute',
    #     action: 'trigger',
    #     id: '654fad6f-adf465df4-a6df4ad6f'
    #   )
    # end
  end

  context 'DELETE' do
    it 'routes /compute/:id to compute#delete' do
      expect(delete: '/compute/54fdaa-6a4df65adf-ad6f4adf6').to route_to(
        controller: 'compute',
        action: 'delete',
        id: '54fdaa-6a4df65adf-ad6f4adf6'
      )
    end

    it 'routes /compute/ to compute#delete' do
      expect(delete: '/compute/').to route_to(
        controller: 'compute',
        action: 'delete'
      )
    end
  end

  context 'PUT' do
    it 'does not route /compute/ to compute' do
      expect(put: '/compute/').not_to be_routable
    end

    it 'routes /compute/:id to compute#update' do
      expect(put: '/compute/54fdaa-6a4df65adf-ad6f4adf6').to route_to(
        controller: 'compute',
        action: 'update',
        id: '54fdaa-6a4df65adf-ad6f4adf6'
      )
    end
  end

end
