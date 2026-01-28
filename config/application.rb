# frozen_string_literal: true

require_relative 'boot'

require 'csv'
require 'rails/all'

Bundler.require(*Rails.groups)

module RailsSurvey
  class Application < Rails::Application
    config.load_defaults 5.2
    config.time_zone = 'Eastern Time (US & Canada)'

    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      if File.exist?(env_file) && !File.zero?(env_file)
        YAML.safe_load(File.open(env_file), aliases: true).each do |key, value|
          value = value.to_s if value.is_a?(Integer)
          ENV[key.to_s] = value
        end
      end
    end

    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
    config.assets.paths << Rails.root.join('vendor', 'assets', 'images')
    config.assets.paths << Rails.root.join('vendor', 'assets', 'lib')
    config.assets.paths << Rails.root.join('vendor', 'assets', 'fonts')
    config.assets.paths << Rails.root.join('vendor', 'assets', 'templates')
    I18n.enforce_available_locales = false
    config.assets.precompile += %w[active_admin.js active_admin.css.scss]
    config.wiki_path = 'wiki.git'
    config.cache_store = :redis_store, "#{ENV['REDIS_CACHE_URL']}/cache", { expires_in: 6.hours }
    config.autoload_paths += Dir[Rails.root.join('app', 'scorers', '{*/}')]
    config.action_controller.include_all_helpers = false
  end
end
