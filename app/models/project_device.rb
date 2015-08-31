# == Schema Information
#
# Table name: project_devices
#
#  id         :integer          not null, primary key
#  project_id :integer
#  device_id  :integer
#  created_at :datetime
#  updated_at :datetime
#

class ProjectDevice < ActiveRecord::Base
  belongs_to :project
  belongs_to :device
end
