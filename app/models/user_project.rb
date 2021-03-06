# frozen_string_literal: true

# == Schema Information
#
# Table name: user_projects
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#

class UserProject < ApplicationRecord
  belongs_to :project
  belongs_to :user
  validates :user_id, presence: true, allow_blank: false
  validates :project_id, presence: true, allow_blank: false
  validates :user_id, uniqueness: { scope: :project_id,
                                    message: 'should have one record per project' }
end
