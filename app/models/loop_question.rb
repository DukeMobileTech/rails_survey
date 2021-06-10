# frozen_string_literal: true

# == Schema Information
#
# Table name: loop_questions
#
#  id                     :integer          not null, primary key
#  instrument_question_id :integer
#  parent                 :string
#  looped                 :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  deleted_at             :datetime
#  option_indices         :string
#  same_display           :boolean          default(FALSE)
#  replacement_text       :text
#

class LoopQuestion < ActiveRecord::Base
  belongs_to :instrument_question, touch: true, counter_cache: true
  acts_as_paranoid
  validates :instrument_question_id, uniqueness: { scope: %i[parent looped] }
  validates :looped, uniqueness: { scope: :parent }

  def looped_position
    instrument_question.instrument.instrument_questions.find_by_identifier(looped)&.number_in_instrument
  end
end
