lock '3.8.1'

set :application, 'rails_survey'
set :repo_url, 'git@github.com:DukeMobileTech/rails_survey.git'
set :use_sudo, false
set :deploy_via, :copy
set :pty, false
set :format, :pretty
set :keep_releases, 5
set :linked_files, %w(config/database.yml config/secret_token.txt config/local_env.yml config/newrelic.yml)
set :linked_dirs, %w(log tmp/pids tmp/cache tmp/sockets vendor/bundle)
set :linked_dirs, fetch(:linked_dirs) + %w(files updates)
set :bundle_binstubs, nil
# Sikekiq configurations
set :sidekiq_default_hooks, true
set :sidekiq_processes, 4
set :sidekiq_config, 'config/sidekiq.yml'
# Wheneverize
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }

# When using Phusion Passenger App Server
namespace :deploy do
  desc 'Restart Application'
  task :restart do
    desc 'restart phusion passenger'
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, current_path.join('tmp/restart.txt')
    end
  end

  after :finishing, 'deploy:cleanup'
  after 'deploy:publishing', 'deploy:restart'
  after 'deploy:published', 'sidekiq:monit:config'
end

namespace :clients do
  task :deploy_on_all do
    on roles(:all), in: :parallel do
      invoke 'deploy'
    end
    invoke 'clients:migrate_on_all'
  end

  task :migrate_on_all do
    on roles(:db), in: :parallel do
      conditionally_migrate = fetch(:conditionally_migrate)
      info '[deploy:migrate] Checking changes in /db/migrate' if conditionally_migrate
      if conditionally_migrate && test("diff -q #{release_path}/db/migrate #{current_path}/db/migrate")
        info '[deploy:migrate] Skip `deploy:migrate` (nothing changed in db/migrate)'
      else
        info '[deploy:migrate] Run `rake db:migrate`'
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, 'db:migrate'
          end
        end
      end
    end
  end
end
