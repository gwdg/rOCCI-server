source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.1'
gem 'warden', '~> 1.2.7'
gem 'mongo'

gem 'rack-cors'
gem 'logstasher'
gem 'bson'

gem 'occi-core', '= 5.0.0.beta.1', require: 'occi/infrastructure-ext' # '~> 5.0.0'

group :development, :test do
  gem 'puma', '~> 3.7'
  gem 'byebug'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Include external bundles
%w[authentication_strategies backends].each do |subdir|
  path = File.join(File.dirname(__FILE__), 'lib', subdir, 'bundles')
  next unless File.directory?(path)

  Dir.glob(File.join(path, "Gemfile.*")) do |gemfile|
      eval(IO.read(gemfile), binding)
  end
end
