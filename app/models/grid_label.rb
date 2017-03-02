# == Schema Information
#
# Table name: grid_labels
#
#  id         :integer          not null, primary key
#  label      :text
#  grid_id    :integer
#  option_id  :integer
#  created_at :datetime
#  updated_at :datetime
#

class GridLabel < ActiveRecord::Base
  include CacheWarmAble
  belongs_to :grid
  belongs_to :option
  after_create :create_options
  validates :label, presence: true, allow_blank: false

  def create_options
    if option_id.blank? && !grid.questions.blank?
      grid.questions.each do |question|
        option = question.options.new(text: label, number_in_question: question.options.count + 1)
        option_id = option.id if option.save
      end
    end
  end
end
