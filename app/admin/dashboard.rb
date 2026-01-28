ActiveAdmin.register_page 'Dashboard' do

  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("active_admin.dashboard") } do
    # div :class => 'blank_slate_container', :id => 'dashboard_default_message' do
    #   span :class => 'blank_slate' do
    #     if current_user.gauth_enabled == 'f'
    #       panel 'Warning' do
    #         para 'You currently do not have two factor authentication enabled.  Please enable it!'
    #         para link_to 'Set up Two Factor Authentication', user_displayqr_path
    #       end
    #     end
    #   end
    # end

    panel 'Projects' do
      table_for Project.all.each do
        column('Name') {|project| link_to project.name, admin_project_path(project.id)}
        column('Responses') {|project| link_to 'Responses', admin_project_surveys_path(project.id)}
        column('Exports') {|project| link_to 'Exports', admin_project_response_exports_path(project.id)}
        column('Variables') {|project| link_to 'Variables', admin_project_questions_path(project.id)}
      end
    end

  end

  def index
    authorize :dashboards, :index?
  end

end
