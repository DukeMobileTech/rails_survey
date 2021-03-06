# frozen_string_literal: true

collection @condition_skips

attributes :id, :instrument_question_id, :question_identifier, :next_question_identifier,
           :question_identifiers, :option_ids, :values, :value_operators, :deleted_at

node :question_id, &:instrument_question_id

node :instrument_id do |nq|
  nq.instrument_question&.instrument_id
end
