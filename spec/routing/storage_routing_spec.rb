require 'spec_helper'

describe 'routing to storage' do

  context 'GET' do
    it 'routes /storage/:id to storage#show' do
      expect(get: '/storage/54fdaa-6a4df65adf-ad6f4adf6').to route_to(
        controller: 'storage',
        action: 'show',
        id: '54fdaa-6a4df65adf-ad6f4adf6'
      )
    end

    it 'routes /storage/ to storage#index' do
      expect(get: '/storage/').to route_to(
        controller: 'storage',
        action: 'index'
      )
    end
  end

  context 'POST' do
    it 'routes /storage/ to storage#create' do
      expect(post: '/storage/').to route_to(
        controller: 'storage',
        action: 'create'
      )
    end

    it 'routes /storage/:id to storage#update' do
      expect(post: '/storage/654fad6f-adf465df4-a6df4ad6f').to route_to(
        controller: 'storage',
        action: 'partial_update',
        id: '654fad6f-adf465df4-a6df4ad6f'
      )
    end

    it 'routes /storage/?action=:action to storage#trigger'# do
    #   expect(post: '/storage/?action=stop').to route_to(
    #     controller: 'storage',
    #     action: 'trigger'
    #   )
    # end

    it 'routes /storage/:id?action=:action to storage#trigger'# do
    #   expect(post: '/storage/654fad6f-adf465df4-a6df4ad6f?action=stop').to route_to(
    #     controller: 'storage',
    #     action: 'trigger',
    #     id: '654fad6f-adf465df4-a6df4ad6f'
    #   )
    # end
  end

  context 'DELETE' do
    it 'routes /storage/:id to storage#delete' do
      expect(delete: '/storage/54fdaa-6a4df65adf-ad6f4adf6').to route_to(
        controller: 'storage',
        action: 'delete',
        id: '54fdaa-6a4df65adf-ad6f4adf6'
      )
    end

    it 'routes /storage/ to storage#delete' do
      expect(delete: '/storage/').to route_to(
        controller: 'storage',
        action: 'delete'
      )
    end
  end

  context 'PUT' do
    it 'does not route /storage/ to storage' do
      expect(put: '/storage/').not_to be_routable
    end

    it 'routes /storage/:id to storage#update' do
      expect(put: '/storage/54fdaa-6a4df65adf-ad6f4adf6').to route_to(
        controller: 'storage',
        action: 'update',
        id: '54fdaa-6a4df65adf-ad6f4adf6'
      )
    end
  end

end
