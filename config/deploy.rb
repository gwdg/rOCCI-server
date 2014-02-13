require 'bundler/capistrano'
require 'rvm/capistrano'

# Warning
Capistrano::CLI.ui.say <<"EOF";

<%= color('IMPORTANT:', RED) %>
   * Capistrano will NOT use sudo to make changes on your server!
   * In order to compile Rubies in RVM, you need libyaml-dev and libssl-dev already installed on the server!
   * In order to check-out the code, you need git binaries installed on the server!
   * The server-side user has to be able to write into /opt/rOCCI-server!
   * Apache2 and Phusion Passenger have to be installed and properly configured!
   * Apache2 VirtualHost must use /opt/rOCCI-server/current/public as DocumentRoot and Directory!
   * Cron has to be installed and the use of crontab allowed for the selected server-side user!

EOF

# Info
Capistrano::CLI.ui.say <<"EOF";
<%= color('ENV defaults:', GREEN) %>
   ROCCI_SERVER_USER = #{ENV['ROCCI_SERVER_USER']}
   ROCCI_HTTP_SERVER = #{ENV['ROCCI_HTTP_SERVER']}
   ROCCI_APP_SERVER = #{ENV['ROCCI_APP_SERVER']}
   ROCCI_DB_SERVER = #{ENV['ROCCI_DB_SERVER']}

EOF

set :application, 'rOCCI-server'
set :repository,  'https://github.com/gwdg/rOCCI-server.git'
ssh_options[:forward_agent] = false

set :use_sudo, false
set :deploy_to, "/opt/#{application}"
set :rails_env, 'production'
set :keep_releases, 2
set :ssh_options,  auth_methods: %w(gssapi-with-mic publickey) 
set :bundle_without,  [:development, :test]

# Remote servers
if ENV['ROCCI_SERVER_USER'] && !ENV['ROCCI_SERVER_USER'].empty?
  set :user, ENV['ROCCI_SERVER_USER']
else
  set(:user) { Capistrano::CLI.ui.ask('What is the name of rOCCI-server\'s server-side user account?  ') { |q|; q.default = 'rocci'; } }
end

if ENV['ROCCI_HTTP_SERVER'] && !ENV['ROCCI_HTTP_SERVER'].empty?
  role :web, ENV['ROCCI_HTTP_SERVER']
else
  role(:web) { Capistrano::CLI.ui.ask('Where is your HTTP server running?  ') { |q|; q.default = 'localhost'; } }
end

if ENV['ROCCI_APP_SERVER'] && !ENV['ROCCI_APP_SERVER'].empty?
  role :app, ENV['ROCCI_APP_SERVER']
else
  role(:app) { Capistrano::CLI.ui.ask('Where is your APP server running?  ') { |q|; q.default = 'localhost'; } }
end

if ENV['ROCCI_DB_SERVER'] && !ENV['ROCCI_DB_SERVER'].empty?
  role :db, ENV['ROCCI_DB_SERVER'], primary: true
else
  role(:db, primary: true) { Capistrano::CLI.ui.ask('Where is your DB server running?  ') { |q|; q.default = 'localhost'; } }
end

# RVM options
# set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"")
set :rvm_ruby_string, 'ruby-2.0.0-p353'
# set :rvm_install_pkgs, %w[libyaml openssl]
# set :rvm_install_pkgs, %w[libyaml openssl]
# set :rvm_install_ruby_params, '--with-opt-dir=~/.rvm/usr'

# Cron
set :whenever_command, 'bundle exec whenever'
set :whenever_environment, defer { rails_env }
set :whenever_roles, [:app]
require 'whenever/capistrano'

# Tasks to run before & after deployment
before 'rvm:install_ruby', 'rvm:install_rvm'
before 'deploy:setup', 'rvm:install_ruby'
before 'deploy', 'deploy:setup'
after 'deploy:restart', 'deploy:cleanup'
# after 'deploy:update_code', 'deploy:migrate'
# after 'deploy:create_symlink', 'deploy:seed'

namespace :deploy do
  task :start { ; }
  task :stop { ; }
  task :restart, roles: :app, except: { no_release: true } do
    run "#{try_sudo} touch #{File.join(current_path, 'tmp', 'restart.txt')}"
  end
end

namespace :remote_debug do
  desc 'Tail production log files'
  task :tail_logs, roles: :app do
    run "tail -f #{shared_path}/log/production.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:host]}: #{data}"
      break if stream == :err
    end
  end

  desc 'Tail cron log files'
  task :tail_cronlogs, roles: :app do
    run "tail -f #{shared_path}/log/cronjobs.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:host]}: #{data}"
      break if stream == :err
    end
  end

  desc 'Open production log files in VIM'
  task :vim_logs, roles: :app do
    tmp = ''
    logs = Hash.new { |h, k| h[k] = '' }

    run "tail -n 500 #{shared_path}/log/production.log" do |channel, stream, data|
      logs[channel[:host]] << data
      break if stream == :err
    end

    logs.each do |host, log|
      tmp << "--- #{host} ---\n\n"
      tmp << "#{log}\n"
    end

    exec "echo '#{tmp}' | vim -"
  end
end
