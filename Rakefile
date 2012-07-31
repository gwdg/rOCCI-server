task :default => 'test:all'

require 'rspec/core/rake_task'
#require 'cucumber/rake/task'

namespace :test do

=begin
  Cucumber::Rake::Task.new(:cucumber) do |t|
    t.cucumber_opts = "--format pretty"

    ENV['COVERAGE'] = "true"
  end
=end

  RSpec::Core::RakeTask.new(:rspec) do |t|
    ENV['COVERAGE'] = "true"
  end

  desc "Run cucumber & rspec to generate aggregated coverage"
  task :all do |t|
    cp File.dirname(__FILE__) + '/etc/backend/dummy/dummy.json', File.dirname(__FILE__) + '/etc/backend/default.json'
    rm "coverage/coverage.data" if File.exist?("coverage/coverage.data")
    Rake::Task['test:rspec'].invoke
    rm File.dirname(__FILE__) + '/etc/backend/default.json'
#    Rake::Task["rcov:cucumber"].invoke
  end
end