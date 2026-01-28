# == Schema Information
#
# Table name: score_schemes
#
#  id            :integer          not null, primary key
#  instrument_id :integer
#  title         :string
#  created_at    :datetime
#  updated_at    :datetime
#  deleted_at    :datetime
#

class ScoreScheme < ActiveRecord::Base
  belongs_to :instrument
  has_many :score_units, dependent: :destroy
  has_many :scores, dependent: :destroy
  validates :title, presence: true, allow_blank: false
  acts_as_paranoid

  def score_unit_count
    score_units.size
  end

  def score_survey(survey)
    score = get_score(survey)
    score_units.each do |unit|
      scheme = SchemeGenerator.generate(unit)
      unit_raw_score = get_raw_score(score, unit)
      score_value = scheme.score(survey, unit)
      unit_raw_score.update(value: score_value)
    end
  end

  def get_score(survey)
    score = scores.where(survey_id: survey.id).try(:first)
    unless score
      score = scores.create(survey_id: survey.id, score_scheme_id: id)
    end
    score
  end

  def get_raw_score(score, unit)
    raw_score = score.raw_scores.where(score_unit_id: unit.id).try(:first)
    unless raw_score
      raw_score = score.raw_scores.create(score_unit_id: unit.id, score_id: score.id)
    end
    raw_score
  end
end
