source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'logstasher', '~> 1.2'
gem 'puma', '~> 3.7'
gem 'rack-attack', '~> 5.0'
gem 'rack-cors', '~> 1.0'
gem 'rails', '~> 5.1'
gem 'responders', '~> 2.4'

gem 'occi-core', '= 5.0.0.beta.18', require: 'occi/infrastructure-ext' # '~> 5.0.0'

group :development, :test do
  gem 'byebug'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rails_best_practices'
  gem 'rubocop', require: false
  gem 'yard'
end

# Include external bundles
Dir.glob(File.join(File.dirname(__FILE__), 'Gemfile.*')) do |gemfile|
  next if gemfile.end_with?('.lock')
  eval(IO.read(gemfile), binding)
end
