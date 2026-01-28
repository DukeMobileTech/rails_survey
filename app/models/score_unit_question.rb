# == Schema Information
#
# Table name: score_unit_questions
#
#  id            :integer          not null, primary key
#  score_unit_id :integer
#  question_id   :integer
#  created_at    :datetime
#  updated_at    :datetime
#  deleted_at    :datetime
#

class ScoreUnitQuestion < ActiveRecord::Base
  belongs_to :score_unit
  belongs_to :question
  acts_as_paranoid
end
