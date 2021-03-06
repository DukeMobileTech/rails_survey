# frozen_string_literal: true

collection @next_questions

attributes :id, :question_identifier, :option_identifier, :value_operator,
           :next_question_identifier, :deleted_at, :value, :complete_survey

node :question_id, &:instrument_question_id

node :instrument_id do |nq|
  nq.instrument_question&.instrument_id
end
