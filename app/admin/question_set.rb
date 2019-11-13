# frozen_string_literal: true

ActiveAdmin.register Question, as: 'QuestionSet' do
  actions :all, except: %i[new edit destroy]
  config.filters = true
  config.per_page = [100, 250, 500]

  collection_action :export, method: :get do
    redirect_to resource_path
  end

  action_item :export do
    link_to 'Export', export_admin_question_sets_path
  end

  index do
    column :question_identifier
    column :question_set_id do |question|
      question.question_set.title
    end
    column :folder_id do |question|
      question.folder.title
    end
    column 'English' do |question|
      raw question.text
    end
    column 'Swahili' do |question|
      raw question.translated 'sw'
    end
    column 'Amharic' do |question|
      raw question.translated 'am'
    end
    column 'Khmer' do |question|
      raw question.translated 'km'
    end
  end

  controller do
    def export
      filename = "questions_#{DateTime.now.to_i}.csv"
      send_data Question.export,
                type: 'text/csv; charset=iso-8859-1; header=present',
                disposition: "attachment; filename=#{filename}"
    end
  end
end
