# == Schema Information
#
# Table name: scores
#
#  id                   :integer          not null, primary key
#  created_at           :datetime
#  updated_at           :datetime
#  survey_id            :integer
#  score_sub_section_id :integer
#

class Score < ActiveRecord::Base
  attr_accessible :survey_id, :score_sub_section_id
  has_many :unit_scores, dependent: :destroy
  has_many :units, through: :unit_scores
  belongs_to :score_sub_section
end