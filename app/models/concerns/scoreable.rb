# frozen_string_literal: true

module Scoreable
  extend ActiveSupport::Concern

  def generate_score(score_units, srs)
    sanitized_scores = srs.where(score_unit_id: score_units.map(&:id)).reject { |rs| rs.weighted_score.nil? }
    return nil if sanitized_scores.empty?

    sum_of_weights = sanitized_scores.inject(0.0) { |sum, item| sum + item.weight }
    sum_of_weighted_scores = sanitized_scores.inject(0.0) { |sum, item| sum + item.weighted_score }
    (sum_of_weighted_scores / sum_of_weights).round(2)
  end
end
