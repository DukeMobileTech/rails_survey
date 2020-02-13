# frozen_string_literal: true

collection @validations

attributes :id, :validation_identifier, :validation_text, :validation_message,
           :relational_operator, :validation_type, :title, :deleted_at

child :translations do
  attributes :id, :validation_id, :text, :language
end
