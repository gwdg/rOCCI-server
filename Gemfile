source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.0.0'
gem 'rails-api', '~> 0.1.0'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use Capistrano for deployment
gem 'capistrano', group: :development
gem 'rvm-capistrano', group: :development

# Use debugger
gem 'debugger', group: [:development, :test]

# Use whenever for scheduled jobs
gem 'whenever', require: false

# Use passenger for deployment (standalone or in Apache2)
gem 'passenger'

# Use simplecov for coverage reports
gem 'simplecov', group: [:development, :test]

# Use RSpec for unit tests
gem 'rspec-rails', '~> 2.0', group: [:development, :test]
gem 'fuubar', group: [:development, :test]

# Use guard to speed-up devel process
gem 'guard-bundler', group: :development
gem 'guard-test', group: :development
gem 'guard-rails', group: :development

# Use notification libs to integrate guard with pop-ups
gem 'rb-inotify', '~> 0.8.8', require: false, group: :development
gem 'libnotify', group: :development

# Use bond+hirb to extend irb
#
# Add the following to your ~/.irbrc:
#
# require 'bond'
# require 'hirb'
#
# Bond.start
# Hirb.enable
#
# Or type it in the current irb session.
gem 'bond', group: :development
gem 'hirb', group: :development

# MongoDB integration
gem 'mongo_mapper', :git => "git://github.com/mongomapper/mongomapper.git", :branch => "master"
gem 'bson_ext'

# AuthN middleware
gem 'warden', :git =>"git://github.com/hassox/warden.git", :branch => "master"

# Sensible logging with LogStash support
gem 'logstasher', :git => "git://github.com/shadabahmed/logstasher.git", :branch => "master"

# Use occi-core for OCCI stuff
gem 'occi-core', '~> 4.1.0'