# == Schema Information
#
# Table name: folders
#
#  id              :integer          not null, primary key
#  question_set_id :integer
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Folder < ActiveRecord::Base
  belongs_to :question_set
  has_many :questions
end
