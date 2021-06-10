# frozen_string_literal: true

# == Schema Information
#
# Table name: multiple_skips
#
#  id                       :integer          not null, primary key
#  question_identifier      :string
#  option_identifier        :string
#  skip_question_identifier :string
#  instrument_question_id   :integer
#  deleted_at               :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  value                    :string
#

class MultipleSkip < ActiveRecord::Base
  belongs_to :option, foreign_key: :option_identifier
  belongs_to :question, foreign_key: :question_identifier
  belongs_to :instrument_question, -> { with_deleted }, touch: true
  delegate :instrument, to: :instrument_question
  acts_as_paranoid
  validates :instrument_question_id, uniqueness: { scope:
    %i[question_identifier option_identifier skip_question_identifier] }

  def skipped_question
    instrument.instrument_questions.where(identifier: skip_question_identifier).first
  end
end
