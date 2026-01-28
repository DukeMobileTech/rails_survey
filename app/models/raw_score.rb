# == Schema Information
#
# Table name: raw_scores
#
#  id            :integer          not null, primary key
#  score_unit_id :integer
#  score_id      :integer
#  value         :float
#  created_at    :datetime
#  updated_at    :datetime
#  uuid          :string
#  score_uuid    :string
#

class RawScore < ActiveRecord::Base
  belongs_to :score_unit
  belongs_to :centralized_score, class_name: 'Score', foreign_key: :score_id
  belongs_to :distributed_score, class_name: 'Score', foreign_key: :score_uuid

  def score
    Score.where('id = ? OR uuid = ?', score_id, score_uuid).try(:first)
  end

  def question_identifiers
    score_unit.questions.pluck(:question_identifier).join(', ')
  end

  def response_texts
    responses = []
    score_unit.questions.each do |question|
      responses << score.survey.response_for_question(question).try(:text)
    end
    responses.join(', ')
  end
end
