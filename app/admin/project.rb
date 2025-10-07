ActiveAdmin.register Project do
  actions :all, except: [:destroy]
  permit_params :name, :description, :survey_aggregator
  scope_to :current_user, unless: proc { current_user.super_admin? }

  member_action :to_csv, method: :get do
    redirect_to resource_path
  end

  action_item :to_csv, only: :show do
    link_to 'Download Dataset', to_csv_admin_project_path(params[:id]), method: :get
  end

  member_action :questions_to_csv, method: :get do
    redirect_to resource_path
  end

  action_item :questions_to_csv, only: :show do
    link_to 'Download Variables', questions_to_csv_admin_project_path(params[:id]), method: :get
  end

  sidebar 'Project Associations', only: :show do
    ul do
      li link_to 'Survey Responses', admin_project_surveys_path(params[:id])
      li link_to 'Survey Exports', admin_project_response_exports_path(params[:id])
      li link_to 'Survey Variables', admin_project_questions_path(params[:id])
      li link_to 'Instruments', admin_project_instruments_path(params[:id])
    end
  end

  index do
    column :id
    column :name do |project|
      link_to truncate(project.name, length: 50), admin_project_path(project.id)
    end
    column :description do |project|
      truncate(project.description, length: 100)
    end
    actions
  end

  show do |project|
    attributes_table do
      row :id
      row :name
      row :description
      row :created_at
      row :updated_at
      row :users do
        ul do
          project.users.each do |user|
            li { user.email }
          end
        end
      end
      row :survey_aggregator
    end
    active_admin_comments
  end

  form do |f|
    f.inputs 'Project Details' do
      f.input :name
      f.input :description
      f.input :survey_aggregator, collection: Settings.metric_keys
    end
    f.actions
  end

  controller do
    def to_csv
      project = Project.find(params[:id])
      temp_file = Tempfile.new(["project-#{project.id}", ".csv"])
      temp_file.write(project.to_csv)
      temp_file.rewind
      send_file temp_file.path, type: 'text/csv; charset=iso-8859-1; header=present',
                  disposition: "attachment; filename=#{project.name}.csv"
    end

    def questions_to_csv
      project = Project.find(params[:id])
      temp_file = Tempfile.new(["project-#{project.id}-questions", ".csv"])
      # temp_file.write(project.questions_to_csv)
      temp_file.write(project.similar_questions_to_csv)
      temp_file.rewind
      send_file temp_file.path, type: 'text/csv; charset=iso-8859-1; header=present',
                  disposition: "attachment; filename=#{project.name}-questions.csv"
    end
  end
end
