# == Schema Information
#
# Table name: diagrams
#
#  id         :bigint           not null, primary key
#  option_id  :integer
#  position   :integer
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  collage_id :integer
#

class Diagram < ApplicationRecord
  belongs_to :option, inverse_of: :diagrams
  belongs_to :collage, inverse_of: :diagrams
  acts_as_paranoid
end
