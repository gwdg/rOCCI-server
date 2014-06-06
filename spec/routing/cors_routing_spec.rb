require 'spec_helper'

describe 'routing to cors' do

  context 'OPTIONS' do
    it 'routes / to cors#index' do
      expect(options: '/').to route_to(
        controller: 'cors',
        action: 'index'
      )
    end

    it 'routes /-/ to cors#index' do
      expect(options: '/-/').to route_to(
        controller: 'cors',
        action: 'index',
        dummy: '-'
      )
    end
  end

end
