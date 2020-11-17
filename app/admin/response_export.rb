ActiveAdmin.register ResponseExport do
  belongs_to :project
  permit_params :project_id, :instrument_id, :instrument_versions, :completion
  actions :all, except: %i[new edit]
  config.filters = false

  collection_action :export_surveys, method: :get do
    redirect_to resource_path
  end

  action_item :export_surveys do
    link_to 'Export Surveys', export_surveys_admin_project_response_exports_path(params[:project_id])
  end

  member_action :long_csv, method: :get do
    redirect_to resource_path
  end

  member_action :long_xlsx, method: :get do
    redirect_to resource_path
  end

  member_action :wide_csv, method: :get do
    redirect_to resource_path
  end

  member_action :wide_xlsx, method: :get do
    redirect_to resource_path
  end

  index do
    column :id do |export|
      link_to export.id, admin_project_response_export_path(export.instrument_id, export.id) if export.instrument_id
    end
    column 'Instrument', sortable: :instrument_title do |export|
      instrument = Instrument.find_by_id(export.instrument_id) if export.instrument_id
      instrument ? (link_to instrument.title, admin_project_instrument_path(instrument.project_id, instrument)) : ''
    end
    column :instrument_versions do |export|
      export.instrument_versions.join(',') if export.instrument_versions
    end
    column 'Progress', :completion
    column 'Long Format', :long_done do |export|
      if export.completion < 100
        'exporting'
      else
        span { link_to 'csv', long_csv_admin_project_response_export_path(params[:project_id], export.id) }
        span { link_to 'xlsx', long_xlsx_admin_project_response_export_path(params[:project_id], export.id) }
      end
    end
    column 'Wide Format', :wide_done do |export|
      if export.completion < 100
        'exporting'
      else
        span { link_to 'csv', wide_csv_admin_project_response_export_path(params[:project_id], export.id) }
        span { link_to 'xlsx', wide_xlsx_admin_project_response_export_path(params[:project_id], export.id) }
      end
    end
    column :updated_at
    actions
  end

  controller do
    before_action :set_response_export, only: %i[long_csv long_xlsx wide_csv wide_xlsx]

    def long_csv
      download('long', 'csv')
    end

    def long_xlsx
      download('long', 'xlsx')
    end

    def wide_csv
      download('wide', 'csv')
    end

    def wide_xlsx
      download('wide', 'xlsx')
    end

    def export_surveys
      project = Project.find(params[:project_id])
      project.instruments.each do |instrument|
        instrument.export_surveys unless instrument.surveys.empty?
      end
      redirect_to admin_project_response_exports_path(params[:project_id])
    end

    private

    def set_response_export
      project = Project.find(params[:project_id])
      @response_export = project.response_exports.find_by_id(params[:id])
    end

    def download(format, extension)
      send_file @response_export.download(format, extension), type: "text/#{extension}", filename:
      "#{@response_export.instrument.title}_#{Time.now.to_i}_#{format}.#{extension}"
    end
  end
end
