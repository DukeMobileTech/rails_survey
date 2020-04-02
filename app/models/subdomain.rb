# frozen_string_literal: true

# == Schema Information
#
# Table name: subdomains
#
#  id         :integer          not null, primary key
#  title      :string
#  domain_id  :integer
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Subdomain < ApplicationRecord
  belongs_to :domain
  has_many :score_units, dependent: :destroy
  has_many :raw_scores, through: :score_units

  acts_as_paranoid

  validates :title, presence: true, allow_blank: false, uniqueness: { scope: [:domain_id] }

  default_scope { order(:title) }

  def score(survey_score)
    sanitized_scores = raw_scores.where(survey_score_id: survey_score.id).reject { |score| score.weighted_score.nil? }
    return nil if sanitized_scores.empty?

    sum_of_weights = sanitized_scores.map(&:weight).inject(0, &:+)
    sum_of_weighted_scores = sanitized_scores.map(&:weighted_score).inject(0, &:+)
    (sum_of_weighted_scores / sum_of_weights).round(2)
  end
end
