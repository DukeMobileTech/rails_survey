# frozen_string_literal: true

require 'rabl'
Rabl.configure do |config|
  config.include_json_root = false
  config.include_child_root = false
  config.cache_all_output = false
  config.cache_sources = false
  config.view_paths = [Rails.root.join('app/views/api')]
end
