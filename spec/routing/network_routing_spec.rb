require 'spec_helper'

describe 'routing to network' do

  context 'GET' do
    it 'routes /network/:id to network#show' do
      expect(get: '/network/54fdaa-6a4df65adf-ad6f4adf6').to route_to(
        controller: 'network',
        action: 'show',
        id: '54fdaa-6a4df65adf-ad6f4adf6'
      )
    end

    it 'routes /network/ to network#index' do
      expect(get: '/network/').to route_to(
       controller: 'network',
       action: 'index'
      )
    end
  end

  context 'POST' do
    it 'routes /network/ to network#create' do
      expect(post: '/network/').to route_to(
        controller: 'network',
        action: 'create'
      )
    end

    it 'routes /network/:id to network#update' do
      expect(post: '/network/654fad6f-adf465df4-a6df4ad6f').to route_to(
        controller: 'network',
        action: 'partial_update',
        id: '654fad6f-adf465df4-a6df4ad6f'
      )
    end

    it 'routes /network/?action=:action to network#trigger'# do
    #   expect(post: '/network/?action=stop').to route_to(
    #     controller: 'network',
    #     action: 'trigger'
    #   )
    # end

    it 'routes /network/:id?action=:action to network#trigger'# do
    #   expect(post: '/network/654fad6f-adf465df4-a6df4ad6f?action=stop').to route_to(
    #     controller: 'network',
    #     action: 'trigger',
    #     id: '654fad6f-adf465df4-a6df4ad6f'
    #   )
    # end
  end

  context 'DELETE' do
    it 'routes /network/:id to network#delete' do
      expect(delete: '/network/54fdaa-6a4df65adf-ad6f4adf6').to route_to(
        controller: 'network',
        action: 'delete',
        id: '54fdaa-6a4df65adf-ad6f4adf6'
      )
    end

    it 'routes /network/ to network#delete' do
      expect(delete: '/network/').to route_to(
        controller: 'network',
        action: 'delete'
      )
    end
  end

  context 'PUT' do
    it 'does not route /network/ to network' do
      expect(put: '/network/').not_to be_routable
    end

    it 'routes /network/:id to network#update' do
      expect(put: '/network/54fdaa-6a4df65adf-ad6f4adf6').to route_to(
        controller: 'network',
        action: 'update',
        id: '54fdaa-6a4df65adf-ad6f4adf6'
      )
    end
  end

end
