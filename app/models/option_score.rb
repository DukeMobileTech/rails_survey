# == Schema Information
#
# Table name: option_scores
#
#  id            :integer          not null, primary key
#  score_unit_id :integer
#  option_id     :integer
#  value         :float
#  created_at    :datetime
#  updated_at    :datetime
#  label         :string
#  exists        :boolean
#  next_question :boolean
#  deleted_at    :datetime
#

class OptionScore < ActiveRecord::Base
  belongs_to :option
  belongs_to :score_unit
  acts_as_paranoid

  # if self belongs_to option, return option.text
  def label
    option ? option.text : read_attribute(:label)
  end

end
