# == Schema Information
#
# Table name: score_units
#
#  id              :integer          not null, primary key
#  score_scheme_id :integer
#  question_type   :string
#  min             :float
#  max             :float
#  weight          :float
#  created_at      :datetime
#  updated_at      :datetime
#  score_type      :integer
#  deleted_at      :datetime
#

class ScoreUnit < ActiveRecord::Base
  belongs_to :score_scheme, touch: true
  has_many :score_unit_questions, dependent: :destroy
  has_many :questions, through: :score_unit_questions
  has_many :option_scores, dependent: :destroy
  has_many :raw_scores
  acts_as_paranoid
  # Add new score_types to the end of the enum to maintain order
  enum score_type: [:single_select, :multiple_select, :multiple_select_sum, :range, :simple_search]

  def self.score_types_to_a
    ar = []
    score_types.map { |key, value| ar << { key: key, value: value } }
    ar
  end
end
