# == Schema Information
#
# Table name: grids
#
#  id            :integer          not null, primary key
#  instrument_id :integer
#  question_type :string(255)
#  name          :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

class Grid < ActiveRecord::Base
  belongs_to :instrument
  has_many :questions, dependent: :destroy
  has_many :grid_labels, dependent: :destroy
  after_save :update_question_types, if: proc { |grid| grid.question_type_changed? }

  def update_question_types
    questions.each do |question|
      question.update_attribute(:question_type, question_type)
    end
  end
end
