require 'spec_helper'

describe 'routing to model' do

  context 'GET' do
    it 'routes /-/ to occi_model#show' do
      expect(get: '/-/').to route_to(
        controller: 'occi_model',
        action: 'show'
      )
    end

    it 'routes /.well-known/org/ogf/occi/-/ to occi_model#show' do
      expect(get: '/.well-known/org/ogf/occi/-/').to route_to(
        controller: 'occi_model',
        action: 'show'
      )
    end
  end

  context 'POST' do
    it 'routes /-/ to occi_model#show' do
      expect(post: '/-/').to route_to(
        controller: 'occi_model',
        action: 'create'
      )
    end

    it 'routes /.well-known/org/ogf/occi/-/ to occi_model#show' do
      expect(post: '/.well-known/org/ogf/occi/-/').to route_to(
        controller: 'occi_model',
        action: 'create'
      )
    end
  end

  context 'DELETE' do
    it 'routes /-/ to occi_model#show' do
      expect(delete: '/-/').to route_to(
        controller: 'occi_model',
        action: 'delete'
      )
    end

    it 'routes /.well-known/org/ogf/occi/-/ to occi_model#show' do
      expect(delete: '/.well-known/org/ogf/occi/-/').to route_to(
        controller: 'occi_model',
        action: 'delete'
      )
    end
  end

  context 'PUT' do
    it 'does not route /-/ to model' do
      expect(put: '/-/').not_to be_routable
    end

    it 'does not route /.well-known/org/ogf/occi/-/ to occi_model' do
      expect(put: '/.well-known/org/ogf/occi/-/').not_to be_routable
    end
  end

end
