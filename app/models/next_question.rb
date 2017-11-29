# == Schema Information
#
# Table name: next_questions
#
#  id                       :integer          not null, primary key
#  question_identifier      :string
#  option_identifier        :string
#  next_question_identifier :string
#  instrument_question_id   :integer
#  created_at               :datetime
#  updated_at               :datetime
#

class NextQuestion < ActiveRecord::Base
  belongs_to :option, foreign_key: :option_identifier
  belongs_to :question, foreign_key: :question_identifier
  belongs_to :instrument_question
end