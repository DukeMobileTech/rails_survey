# frozen_string_literal: true

# == Schema Information
#
# Table name: projects
#
#  id                :integer          not null, primary key
#  name              :string
#  description       :text
#  created_at        :datetime
#  updated_at        :datetime
#  survey_aggregator :string
#

class Project < ApplicationRecord
  include SynchAble
  has_many :instruments, dependent: :destroy
  has_many :instrument_questions, through: :instruments
  has_many :questions, through: :instrument_questions
  has_many :next_questions, through: :instrument_questions
  has_many :multiple_skips, through: :instrument_questions
  has_many :condition_skips, through: :instrument_questions
  has_many :follow_up_questions, through: :instrument_questions
  has_many :options, through: :questions
  has_many :option_sets, through: :questions
  has_many :option_in_option_sets, through: :option_sets
  has_many :displays, through: :instruments
  has_many :surveys, through: :instruments
  has_many :project_devices, dependent: :destroy
  has_many :devices, through: :project_devices
  has_many :responses, through: :surveys
  has_many :response_images, through: :responses
  has_many :user_projects, dependent: :destroy
  has_many :users, through: :user_projects
  has_many :response_exports, through: :instruments
  has_many :response_images_exports, through: :response_exports
  has_many :images, through: :questions
  has_many :randomized_factors, through: :instruments
  has_many :randomized_options, through: :randomized_factors
  has_many :question_randomized_factors, through: :questions
  has_many :sections, through: :instruments
  has_many :project_device_users
  has_many :device_users, through: :project_device_users
  has_many :instrument_rules, through: :instruments
  has_many :grids, through: :instruments
  has_many :grid_labels, through: :grids
  has_many :metrics, through: :instruments
  has_many :rosters, dependent: :destroy
  has_many :score_schemes, through: :instruments
  has_many :domains, through: :score_schemes
  has_many :subdomains, through: :score_schemes
  has_many :score_units, through: :score_schemes
  has_many :option_scores, through: :score_units
  has_many :score_unit_questions, through: :score_units
  has_many :survey_scores, through: :surveys
  has_many :raw_scores, through: :survey_scores
  has_many :critical_responses, through: :instruments
  has_many :loop_questions, through: :instruments
  has_many :published_instruments, -> { published }, class_name: 'Instrument'
  has_many :tasks, through: :instruments
  has_many :task_option_sets, through: :tasks

  validates :name, presence: true, allow_blank: false
  validates :description, presence: true, allow_blank: true

  def api_option_sets
    option_set_ids = api_questions.pluck(:option_set_id) + api_questions.pluck(:special_option_set_id)
    OptionSet.includes(:instruction, :option_set_translations).where(id: option_set_ids.uniq)
  end

  def api_options
    option_ids = api_option_in_option_sets.pluck(:option_id).uniq + api_diagrams.pluck(:option_id).uniq
    Option.includes(:translations).where(id: option_ids)
  end

  def api_option_collages
    ids = api_option_in_option_sets.pluck(:id).uniq
    OptionCollage.where(option_in_option_set_id: ids)
  end

  def api_instrument_questions
    InstrumentQuestion.includes(:instrument, question: %i[instruction option_set], translations: [:question]).where(instrument_id: published_instruments.pluck(:id))
  end

  def api_option_in_option_sets
    OptionInOptionSet.where(option_set_id: api_option_sets.pluck(:id))
  end

  def api_questions
    Question.where(id: api_instrument_questions.pluck(:question_id).uniq)
  end

  def api_question_collages
    ids = api_questions.pluck(:id).uniq
    QuestionCollage.where(question_id: ids)
  end

  def api_displays
    Display.includes(:display_translations).where(instrument_id: published_instruments.pluck(:id))
  end

  def api_display_instructions
    DisplayInstruction.includes(:instrument_question).where(display_id: api_displays.pluck(:id))
  end

  def api_validations
    Validation.where(id: api_questions.pluck(:validation_id).uniq)
  end

  def api_instructions
    api_instruction_ids = api_questions.pluck(:instruction_id).compact +
                          api_questions.pluck(:pop_up_instruction_id).compact +
                          api_questions.pluck(:after_text_instruction_id).compact +
                          api_option_sets.pluck(:instruction_id).compact +
                          api_display_instructions.pluck(:instruction_id).compact +
                          critical_responses.with_deleted.pluck(:instruction_id).compact +
                          api_option_in_option_sets.pluck(:instruction_id).compact
    Instruction.includes(:instruction_translations).where(id: api_instruction_ids.uniq)
  end

  def api_collages
    collage_ids = api_option_collages.pluck(:collage_id) + api_question_collages.pluck(:collage_id)
    Collage.where(id: collage_ids.uniq)
  end

  def api_diagrams
    Diagram.where(collage_id: api_collages.pluck(:id).uniq)
  end

  def special_option_sets
    questions.uniq.collect(&:special_option_set).uniq.compact
  end

  def non_responsive_devices
    devices.includes(:surveys).where('surveys.updated_at < ?', Settings.danger_zone_days.days.ago).order('surveys.updated_at ASC')
  end

  def instrument_response_exports
    ResponseExport.where(instrument_id: instrument_ids).order('created_at desc')
  end

  def daily_response_count
    count_per_day = {}
    array = []
    response_count_per_period(:group_responses_by_day).each do |day, count|
      count_per_day[day.to_s[5..9]] = count.inject { |sum, x| sum + x }
    end
    array << count_per_day
  end

  def hourly_response_count
    count_per_hour = {}
    array = []
    response_count_per_period(:group_responses_by_hour).each do |hour, count|
      count_per_hour[hour.to_s] = count.inject { |sum, x| sum + x }
    end
    array << sanitize(count_per_hour)
  end

  def device_surveys(device)
    surveys.where(device_uuid: device.identifier)
  end

  def aggregators
    if survey_aggregator == 'device_uuid'
      aggs = []
      uuids = surveys.pluck(:device_uuid).uniq
      uuids.each do |uuid|
        aggs << surveys.find_by_device_uuid(uuid)
      end
      aggs
    elsif survey_aggregator == 'Center ID'
      surveys.select(&:center_id).uniq
    elsif survey_aggregator == 'Participant ID'
      surveys.select(&:participant_id).uniq
    else
      surveys
    end
  end

  def aggregator_label(aggregator)
    if survey_aggregator == 'device_uuid'
      devices.where(identifier: aggregator.device_uuid).try(:first).try(:label)
    elsif survey_aggregator == 'Center ID'
      aggregator.center_id
    elsif survey_aggregator == 'Participant ID'
      aggregator.participant_id
    else
      aggregator.uuid
    end
  end

  def aggregator_survey_count(agg)
    surveys_by_aggregator(agg).size
  end

  def surveys_by_aggregator(agg)
    if survey_aggregator == 'device_uuid'
      surveys.where(device_uuid: agg.device_uuid)
    elsif survey_aggregator == 'Center ID'
      surveys.select { |s| s.center_id == agg.center_id }
    elsif survey_aggregator == 'Participant ID'
      surveys.select { |s| s.participant_id == agg.participant_id }
    else
      surveys
    end
  end

  def survey_aggregator
    read_attribute(:survey_aggregator).nil? ? 'device_uuid' : read_attribute(:survey_aggregator)
  end

  private

  def sanitize(hash)
    (0..23).each do |h|
      hour = format '%02d', h
      hash[hour] = 0 unless hash.key?(hour)
    end
    hash
  end

  def response_count_per_period(method)
    grouped_responses = []
    instruments.each do |instrument|
      instrument.surveys.each do |survey|
        grouped_responses << survey.send(method)
      end
    end
    merge_period_counts(grouped_responses)
  end

  def merge_period_counts(grouped_responses)
    grouped_responses.map(&:to_a).flatten(1).each_with_object({}) { |(k, v), h| (h[k] ||= []) << v; }
  end
end
