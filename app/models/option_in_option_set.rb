# frozen_string_literal: true
# == Schema Information
#
# Table name: option_in_option_sets
#
#  id                 :integer          not null, primary key
#  option_id          :integer          not null
#  option_set_id      :integer          not null
#  number_in_question :integer          not null
#  deleted_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  special            :boolean          default(FALSE)
#  is_exclusive       :boolean          default(FALSE)
#

class OptionInOptionSet < ActiveRecord::Base
  default_scope { order('option_in_option_sets.special ASC, option_in_option_sets.number_in_question ASC') }
  belongs_to :option
  belongs_to :option_set, touch: true, counter_cache: true
  has_paper_trail
  acts_as_paranoid
  after_save :set_special
  validates :option_set_id, uniqueness: { scope: %i[option_id number_in_question] }

  private

  def set_special
    update_columns(special: true) if option_set.special
  end
end
