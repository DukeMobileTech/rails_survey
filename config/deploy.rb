lock '3.2.1'

set :application, 'rails_survey' 
set :scm, :git 
set :repo_url, 'git@github.com:DukeMobileTech/rails_survey.git'
set :use_sudo, false
set :rails_env, 'production'
set :deploy_via, :copy
set :ssh_options, { :forward_agent => true, :port => 2222 }
set :pty, false
set :format, :pretty
set :keep_releases, 5
set :linked_files, %w{config/database.yml config/secret_token.txt config/local_env.yml config/newrelic.yml}
set :linked_dirs, %w(bin log tmp/pids tmp/cache tmp/sockets vendor/bundle)
set :linked_dirs, fetch(:linked_dirs) + %w{ files updates }
set :branch, 'master'
set :sidekiq_pid, File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid')
set :sidekiq_log, File.join(shared_path, 'log', 'sidekiq.log')
set :sidekiq_concurrency, 15
set :sidekiq_processes, 2

namespace :deploy do
  desc 'Restart Application'
  task :restart do
    desc "restart node"
    on roles(:app), in: :sequence, wait: 5 do
      execute "sudo restart realtime-app || sudo start realtime-app"
    end
    desc "restart phusion passenger"
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, current_path.join('tmp/restart.txt')
    end  
  end

  task :npm_install do
    on roles(:app) do
      execute "cd #{release_path}/node && sudo rm -rf node_modules && npm install"
    end 
  end
  
  desc "Monitor redis"
  task :config_redis do
    on roles(:app) do
      execute "sudo mv #{release_path}/config/deploy/shared/redis.erb /etc/monit/conf.d/redis_rails_survey.conf"
    end
  end 
  
  desc "Monitor apache2"
  task :config_apache2 do
    on roles(:app) do
      execute "sudo mv #{release_path}/config/deploy/shared/apache2.erb /etc/monit/conf.d/apache2_rails_survey.conf"
    end
  end

  desc 'Monitor Sidekiq'
  task :config_sidekiq do
    on roles(:app) do
      execute "sudo mv #{release_path}/config/deploy/shared/sidekiq.erb /etc/monit/conf.d/sidekiq_rails_survey.conf"
    end
  end
  
  desc "Restart monit service"
  task :restart_monit do
    on roles(:app) do
      execute "sudo service monit restart"
    end
  end
  
  after :finishing, 'deploy:cleanup'
  after 'deploy:publishing', 'deploy:restart'
  after 'deploy:updated', 'deploy:npm_install'
  after 'deploy:published', 'sidekiq:monit:config'
  after 'deploy:published', 'deploy:config_redis'
  after 'deploy:published', 'deploy:config_apache2'
  after 'deploy:published', 'deploy:config_sidekiq'
  after 'deploy:published', 'deploy:restart_monit'
end
