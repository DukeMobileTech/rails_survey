class AddCompleteSurveyToNextQuestion < ActiveRecord::Migration[4.2]
  def change
    remove_column :options, :complete_survey
    add_column :next_questions, :complete_survey, :boolean
  end
end
