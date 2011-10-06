ssh_options[:forward_agent] = true
ssh_options[:paranoid] = false
default_run_options[:pty] = true # Must be set for the password prompt from git to work

set :application, "redmine"

set :scm, 'git'
set :repository, "git@github.com:ChuguluGames/redmine.git"

task :prod do
  set :type_server, "prod"
  set :servername, "prod.chugulu.com"
  set :home, "/home/redmine/www"
  server servername, :web, :app, :db
  role :app, servername, :memcached => true
  role :web, servername
  role :db,  servername, :primary => true
  set :deploy_to, home
  set :runner, 'redmine'
  set :user, "redmine"
  set :branch, "master"
end


set :deploy_via, :remote_cache
set :use_sudo, false

set :migrate_env, ''

task :uname do
  server servame, :web, :app, :db
  run "uname -a"
end

namespace :bundler do

  task :install, :roles => :app do
    run "cd #{current_release} && bundle install --path .bundle --without test"
  end

  task :create_symlink, :roles => :app do
    shared_dir = File.join(shared_path, 'bundle')
    release_dir = File.join(current_release, '.bundle')
    run("mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}")
  end

end

namespace :deploy do
  desc "Tell Passenger to restart the app."
  task :restart do
    run "touch #{current_path}/tmp/restart.txt" 
  end

  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/config/environments/production.rb #{release_path}/config/environments/production.rb"
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end  
end

# HOOKS

after "deploy:update_code" do
  deploy.symlink_shared
end

# Automatically clean versions by keeping the 5 last versions
after "deploy" do
  bundler.create_symlink
  bundler.install
  deploy.cleanup
end
