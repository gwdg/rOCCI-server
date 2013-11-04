require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'app/**/*.rb']
  t.options = ['--readme', 'README.md', '--files', 'LICENSE']
end