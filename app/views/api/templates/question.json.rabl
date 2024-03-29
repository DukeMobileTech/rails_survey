attributes :id, :text, :question_type, :question_identifier, :instrument_id,
           :created_at, :updated_at, :deleted_at, :reg_ex_validation, :number_in_instrument,
           :reg_ex_validation_message, :identifies_survey, :instructions, :child_update_count,
           :grid_id, :number_in_grid, :instrument_version_number, :section_id, :critical,
           :option_count, :image_count, :instrument_version, :question_version, :task_id,
           :record_audio

child :diagrams do |_d|
  attributes :id, :option_id, :question_id, :position, :deleted_at
end
