class AddResponseSurveyUuidIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :responses, :survey_uuid
    add_index :responses, :time_started
    add_index :responses, :time_ended
  end
end
