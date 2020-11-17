# frozen_string_literal: true

ActiveAdmin.register Survey do
  belongs_to :project
  sidebar 'Survey Associations', only: :show do
    ul do
      li link_to 'Responses', admin_survey_responses_path(params[:id])
    end
  end

  sidebar :versionate, partial: 'layouts/version', only: :show

  permit_params :instrument_id, :instrument_version_number, :uuid, :device_id,
                :instrument_title, :device_uuid, :latitude, :longitude, :metadata,
                :completion_rate

  config.sort_order = 'id_desc'
  config.per_page = [50, 100]
  config.filters = true
  filter :id
  filter :uuid
  filter :device_label
  filter :metadata

  collection_action :calculate_completion_rates, method: :get do
    redirect_to admin_project_surveys_path(params[:project_id])
  end

  action_item :calculate_completion_rates, only: :index do
    link_to 'Recalculate Completion Rates',
            calculate_completion_rates_admin_project_surveys_path(params[:project_id])
  end

  collection_action :remove_duplicates, method: :get do
    redirect_to admin_project_surveys_path(params[:project_id])
  end

  action_item :remove_duplicates, only: :index do
    link_to 'Remove Duplicate Responses',
            remove_duplicates_admin_project_surveys_path(params[:project_id])
  end

  member_action :download, method: :get do
    redirect_to resource_path
  end

  controller do
    def calculate_completion_rates
      project = Project.find(params[:project_id])
      project.instruments.each do |instrument|
        instrument.surveys.each do |survey|
          SurveyPercentWorker.perform_async(survey.id)
        end
      end
      redirect_to admin_project_surveys_path(params[:project_id])
    end

    def remove_duplicates
      RakeTaskWorker.perform_async('response_cleanup')
      redirect_to admin_project_surveys_path(params[:project_id])
    end

    def show
      @survey = Survey.includes(versions: :item).find(params[:id])
      @versions = @survey.versions
      @survey = @survey.versions[params[:version].to_i].reify if params[:version]
      show! # it seems to need this
    end

    def download
      survey = Survey.find(params[:id])
      pdf = SurveyPdf.new(survey, 2)
      name = "#{survey.identifier}.pdf"
      file = Tempfile.new(name)
      pdf.save_as(file.path)
      send_file file, type: 'application/pdf', filename: name
    end
  end

  index do
    selectable_column
    column :id do |survey|
      link_to survey.id, admin_project_survey_path(params[:project_id], survey.id)
    end
    column :uuid
    column 'Identifier', &:identifier
    column 'Instrument', sortable: :instrument_title do |survey|
      link_to survey.instrument_title, "/projects/#{survey.instrument.project_id}/instruments/#{survey.instrument_id}/displays"
    end
    column 'Versions', sortable: :instrument_version_number, &:instrument_version_number
    column :language
    column 'When', sortable: :created_at do |survey|
      time_ago_in_words(survey.created_at) + ' ago'
    end
    column 'Rate', :completion_rate
    column 'Received', :responses do |survey|
      link_to "#{survey.responses.size} responses", admin_survey_responses_path(survey.id)
    end
    column 'Completed', :completed_responses_count
    column 'Download' do |survey|
      link_to 'PDF', download_admin_project_survey_path(params[:project_id], survey.id)
    end
    actions
  end

  form do |f|
    f.inputs 'Survey Details' do
      f.input :metadata
    end
    f.actions
  end
end
