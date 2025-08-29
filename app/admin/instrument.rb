ActiveAdmin.register Instrument do
  belongs_to :project
  permit_params :title, :language, :alignment, :previous_question_count, :child_update_count, :published, :show_instructions, :project_id
  scope_to :current_user, unless: proc { current_user.super_admin? }
  actions :all, except: [:new, :destroy, :edit]

  member_action :to_csv, method: :get do
    redirect_to resource_path
  end

  action_item :to_csv, only: :show do
    link_to 'Download CSV', to_csv_admin_project_instrument_path(params[:project_id], params[:id]), method: :get
  end

  form do |f|
    f.inputs 'Instrument Details' do
      f.input :project, collection: Project.all { |i| [i.name, i.id] }
      f.input :title
      f.input :language, collection: Settings.languages
      f.input :published
      f.input :show_instructions
    end
    f.actions
  end

  controller do
    def to_csv
      @instrument = Instrument.find(params[:id])
      temp_file = Tempfile.new(["instrument-#{@instrument.id}", ".csv"])
      temp_file.write(@instrument.to_csv)
      temp_file.rewind
      send_file temp_file.path, type: 'text/csv; charset=iso-8859-1; header=present',
                  disposition: "attachment; filename=#{@instrument.title}_#{@instrument.current_version_number}.csv"
    end
  end
end
