# frozen_string_literal: true

# == Schema Information
#
# Table name: domains
#
#  id              :integer          not null, primary key
#  title           :string
#  score_scheme_id :integer
#  deleted_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  weight          :float
#  name            :string
#

class Domain < ApplicationRecord
  include Scoreable
  belongs_to :score_scheme
  has_many :subdomains, dependent: :destroy
  has_many :raw_scores, through: :subdomains
  has_many :score_units, through: :subdomains
  has_many :domain_scores, dependent: :destroy
  has_many :subdomain_scores, through: :subdomains

  acts_as_paranoid

  validates :title, presence: true, allow_blank: false, uniqueness: { scope: [:score_scheme_id] }

  def score(survey_score)
    center = survey_score.center
    score_sum = generate_score(score_units, survey_score.id, center)
    domain_score = domain_scores.where(survey_score_id: survey_score.id).first
    if domain_score
      domain_score.update_columns(score_sum: score_sum)
    else
      DomainScore.create(domain_id: id, survey_score_id: survey_score.id, score_sum: score_sum)
    end
    score_sum
  end
end
