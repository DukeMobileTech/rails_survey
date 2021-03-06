# frozen_string_literal: true

# == Schema Information
#
# Table name: score_units
#
#  id               :integer          not null, primary key
#  weight           :float
#  created_at       :datetime
#  updated_at       :datetime
#  score_type       :string
#  deleted_at       :datetime
#  subdomain_id     :integer
#  title            :string
#  base_point_score :float
#  institution_type :string
#  notes            :text
#

class ScoreUnit < ApplicationRecord
  belongs_to :subdomain
  has_many :score_unit_questions, dependent: :destroy
  has_many :option_scores, through: :score_unit_questions
  has_many :raw_scores, dependent: :destroy
  delegate :score_scheme, to: :subdomain

  acts_as_paranoid

  validates :subdomain_id, presence: true, allow_blank: false
  validates :title, presence: true, uniqueness: { scope: [:subdomain_id] }

  def question_identifiers
    score_unit_questions.map { |suq| suq.instrument_question.identifier }.join(',')
  end

  def option_score_count
    option_scores.size
  end

  def domain_id
    subdomain.domain_id
  end

  def domain_title
    subdomain.domain.title
  end

  def domain_name
    subdomain.domain.name
  end

  def subdomain_title
    subdomain.title
  end

  def subdomain_name
    subdomain.name
  end

  def copy
    new_copy = dup
    new_copy.title = "#{title}_copy"
    new_copy.save!
    score_unit_questions.each do |q|
      new_q = q.dup
      new_q.score_unit_id = new_copy.id
      new_q.save!
      q.option_scores.each do |os|
        new_os = os.dup
        new_os.score_unit_question_id = new_q.id
        new_os.save!
      end
    end
    new_copy
  end

  def generate_score(survey, raw_score)
    if score_unit_questions.empty? # Placeholder
      iq = score_scheme.instrument.instrument_questions.where(identifier: title).first
      ScoreUnitQuestion.create(score_unit_id: id, instrument_question_id: iq.id) if iq
      reload
    end
    response, value = score(survey)
    raw_score.value = value
    raw_score.response_id = response.id if response
    raw_score.save
  end

  def selected_option_scores(survey, scores)
    score_unit_questions.each do |suq|
      response = suq.response(survey)
      next unless response

      response_option_identifiers = suq.option_identifiers(response)
      next unless response_option_identifiers

      scores.concat(suq.option_scores.where(option_identifier: response_option_identifiers))
    end
    scores
  end

  def average(survey, scores, response)
    scores = selected_option_scores(survey, scores)
    scores = scores.reject { |s| s.value.nil? }
    if scores.empty?
      return response, nil
    else
      return response, scores.sum(&:value) / scores.size
    end
  end

  def match(survey, scores, response)
    score_unit_questions.each do |suq|
      response = suq.response(survey)
      next unless response

      response_option = suq.option(response)
      next unless response_option

      option_score = option_scores.where(option_identifier: response_option.identifier).first
      if title == 'cwb17' && response.text == '0'
        response1 = survey.responses.find_by_question_identifier('sdm1')&.text&.split(',')[0]
        option_score.value = response1 == '1' ? 7 : 3
      end
      scores << option_score if option_score
    end
    [response, scores.reject { |s| s.value.nil? }.max_by(&:value).try(:value)]
  end

  def lowest(survey, scores, response)
    scores = selected_option_scores(survey, scores)
    [response, scores.reject { |s| s.value.nil? }.min_by(&:value).try(:value)]
  end

  def highest(survey, scores, response)
    scores = selected_option_scores(survey, scores)
    [response, scores.reject { |s| s.value.nil? }.max_by(&:value).try(:value)]
  end

  def sum(survey, scores, response)
    score_unit_questions.each do |suq|
      response = suq.response(survey)
      next unless response

      response_option_identifiers = suq.option_identifiers(response)
      next unless response_option_identifiers

      o_scores = suq.option_scores.where(option_identifier: response_option_identifiers)
      if title == 'grp2'
        r_text = response.text.split(',')
        o_scores.each do |o_s|
          index = suq.option_index(o_s.option)
          if index == 0
            o_s.value = 0
          elsif index == 1
            o_s.value = r_text[1].to_i * -1
          elsif index == 2
            o_s.value = r_text[2].to_i * -2
          elsif index == 3
            o_s.value = r_text[3].to_i * -3
          end
        end
      end
      scores.concat(o_scores)
    end
    return response, nil if scores.empty?

    score_value = scores.sum(&:value) + base_point_score
    if score_value > 7
      score_value = 7
    elsif score_value < 1
      score_value = 1
    end
    [response, score_value]
  end

  def calculation(survey, _scores, response)
    score_value = nil
    score_unit_questions.each do |suq|
      response = suq.response(survey)
      next if response.nil? || response.text.blank?

      if suq.instrument_question.identifier == 'sla15'
        age_scores = []
        resps = response.text.split(',', -1)
        resps.each_with_index do |item, index|
          next if item.blank? || item == '0'

          age_scores << sleep_score(item, index)
        end
        score_value = if age_scores.empty?
                        nil
                      else
                        (age_scores.sum(0.0) / age_scores.size).round(2)
                      end
      elsif suq.instrument_question.identifier == 'sdm6'
        left_count = response.text.split(',').inject(0.0) { |sum, ans| sum + ans.to_i }
        total_response = survey.responses.where(question_identifier: 'sdm1').first
        next if total_response.nil? || total_response.text.blank?

        total_count = total_response.text.split(',').inject(0.0) { |sum, ans| sum + ans.to_i }
        rate = left_count / total_count

        if rate == 0.0
          score_value = 7
        elsif rate <= 0.25
          score_value = 5
        elsif rate > 0.25 && rate <= 0.5
          score_value = 3
        elsif rate > 0.5
          score_value = 1
        end
      elsif suq.instrument_question.identifier == 'grp3'
        grp2 = survey.responses.where(question_identifier: 'grp2').first
        next if grp2.nil? || grp2.text.blank?

        rate = response.text.to_i / grp2.text.split(',').inject(0.0) { |sum, ans| sum + ans.to_i }
        center = score_scheme.centers.find_by(identifier: survey.identifier)
        if center.center_type == 'CDA'
          if rate <= 0.01
            score_value = 1
          elsif rate > 0.01 && rate <= 0.2
            score_value = 2
          elsif rate > 0.2 && rate <= 0.4
            score_value = 3
          elsif rate > 0.4 && rate <= 0.6
            score_value = 4
          elsif rate > 0.6 && rate <= 0.8
            score_value = 5
          elsif rate > 0.8 && rate <= 0.99
            score_value = 6
          elsif rate > 0.99
            score_value = 7
          end
        elsif center.center_type == 'CDI' || center.center_type == 'CBI'
          score_value = rate > 0.0 ? 7 : 1
        end
      elsif suq.instrument_question.identifier == 'chs6'
        resp = response.text.split(',')
        resp.reject! { |str| str.strip.blank? }
        avg = resp.inject(0.0) { |sum, ans| sum + ans.to_i } / resp.size
        if avg < 15
          score_value = 7
        elsif avg >= 15 && avg <= 30
          score_value = 5
        elsif avg > 30 && avg <= 60
          score_value = 3
        elsif avg > 60
          score_value = 1
        end
      end
    end
    [response, score_value]
  end

  def score(survey)
    scores = []
    response = nil
    case score_type
    when 'AVERAGE'
      average(survey, scores, response)
    when 'MATCH'
      match(survey, scores, response)
    when 'LOWEST'
      lowest(survey, scores, response)
    when 'HIGHEST'
      highest(survey, scores, response)
    when 'SUM'
      sum(survey, scores, response)
    when 'CALCULATION'
      calculation(survey, scores, response)
    else
      [nil, nil]
    end
  end

  def sleep_score(item, index)
    hours = item.to_i
    case index
    when 0
      if hours <= 11 || hours >= 20
        1
      elsif hours >= 14 && hours <= 17
        7
      else
        5
      end
    when 1
      if hours <= 9 || hours >= 19
        1
      elsif hours >= 12 && hours <= 16
        7
      else
        5
      end
    when 2
      if hours <= 8 || hours >= 15
        1
      elsif hours >= 11 && hours <= 14
        7
      else
        5
      end
    when 3
      if hours <= 7 || hours >= 16
        1
      elsif hours >= 10 && hours <= 13
        7
      else
        5
      end
    when 4
      if hours <= 6 || hours >= 15
        1
      elsif hours >= 9 && hours <= 12
        7
      else
        5
      end
    when 5
      if hours <= 5 || hours >= 13
        1
      elsif hours >= 8 && hours <= 10
        7
      else
        5
      end
    when 6
      if hours <= 4 || hours >= 12
        1
      elsif hours >= 7 && hours <= 9
        7
      else
        5
      end
    end
  end

  def str_title
    title.scan(/\D/).join('')
  end

  def int_title
    title.scan(/\d/).join('')&.to_i
  end
end
