# frozen_string_literal: true

ActiveAdmin.register Option, as: 'OptionSet' do
  actions :all, except: %i[new edit destroy]
  config.filters = true
  config.per_page = [100, 250, 500]

  collection_action :export, method: :get do
    redirect_to resource_path
  end

  action_item :export do
    link_to 'Export', export_admin_option_sets_path
  end

  index do
    column :identifier
    column 'Option Sets' do |option|
      raw option.option_set_titles
    end
    column 'English', &:text
    column 'Swahili' do |option|
      raw option.translated 'sw'
    end
    column 'Amharic' do |option|
      raw option.translated 'am'
    end
    column 'Khmer' do |option|
      raw option.translated 'km'
    end
  end

  controller do
    def export
      filename = "options_#{DateTime.now.to_i}.csv"
      send_data Option.export,
                type: 'text/csv; charset=iso-8859-1; header=present',
                disposition: "attachment; filename=#{filename}"
    end
  end
end
