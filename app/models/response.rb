# frozen_string_literal: true
# == Schema Information
#
# Table name: responses
#
#  id                  :integer          not null, primary key
#  question_id         :integer
#  text                :text
#  other_response      :text
#  created_at          :datetime
#  updated_at          :datetime
#  survey_uuid         :string
#  special_response    :string
#  time_started        :datetime
#  time_ended          :datetime
#  question_identifier :string
#  uuid                :string
#  device_user_id      :integer
#  question_version    :integer          default(-1)
#  deleted_at          :datetime
#  randomized_data     :text
#  rank_order          :string
#  other_text          :text
#

class Response < ActiveRecord::Base
  belongs_to :instrument_question, foreign_key: :question_identifier, primary_key: :identifier
  belongs_to :survey, foreign_key: :survey_uuid, primary_key: :uuid, touch: true
  delegate :device, to: :survey
  delegate :instrument, to: :survey
  delegate :project, to: :survey
  delegate :instrument_version_number, to: :survey
  delegate :instrument_version, to: :survey
  has_one :response_image, foreign_key: :response_uuid, primary_key: :uuid
  belongs_to :device_user
  acts_as_paranoid
  has_paper_trail on: %i[update destroy]
  validates :survey, presence: true
  validates :uuid, presence: true, allow_blank: false, uniqueness: true
  after_destroy :calculate_response_rate

  def question
    if instrument_question
      instrument_question.question
    else
      survey.question_by_identifier(question_identifier)
    end
  end

  def calculate_response_rate
    job = Sidekiq::ScheduledSet.new.find do |entry|
      entry.item['class'] == 'SurveyPercentWorker' && entry.item['args'].first == survey.id
    end
    SurveyPercentWorker.perform_in(30.minutes, survey.id) unless job
  end

  def to_s
    if instrument_question.nil? || instrument_question.options.empty?
      text
    else
      instrument_question.options[text.to_i].to_s
    end
  end

  def grouped_responses
    group(:created_at)
  end

  def time_taken_in_seconds
    time_ended - time_started if time_ended && time_started
  end

  def is_critical
    return false if !question
    
    if !question.select_one_variant? && !question.select_multiple_variant? && !question.list_of_boxes_variant?
      false
    elsif text.blank?
      false
    else
      resps = text.split(Settings.list_delimiter)
      options = question.options
      response_identifiers = []
      resps.each do |ind|
        option = options[ind.to_i]
        response_identifiers.push(option.identifier) if option
      end
      identifiers = question.critical_responses.pluck(:option_identifier)
      !(response_identifiers & identifiers).empty? # Array intersection
    end
  end
end
