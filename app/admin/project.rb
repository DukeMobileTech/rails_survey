ActiveAdmin.register Project do

  index do
    column "Name" do |text|
      truncate(text.name, length: 50)
    end
    column "Description" do |text|
      truncate(text.description, length: 100)
    end
    column :created_at
    column :updated_at
    default_actions
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
            li {user.email}
          end
        end
      end
    end
    active_admin_comments
  end


end
