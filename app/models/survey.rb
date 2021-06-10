# frozen_string_literal: true

# == Schema Information
#
# Table name: surveys
#
#  id                        :integer          not null, primary key
#  instrument_id             :integer
#  created_at                :datetime
#  updated_at                :datetime
#  uuid                      :string
#  device_id                 :integer
#  instrument_version_number :integer
#  instrument_title          :string
#  device_uuid               :string
#  latitude                  :string
#  longitude                 :string
#  metadata                  :text
#  completion_rate           :string
#  device_label              :string
#  deleted_at                :datetime
#  language                  :string
#  skipped_questions         :text
#  completed_responses_count :integer
#

class Survey < ActiveRecord::Base
  belongs_to :instrument
  belongs_to :device
  belongs_to :roster, foreign_key: :roster_uuid, primary_key: :uuid
  has_many :instrument_questions, through: :instrument
  has_many :responses, foreign_key: :survey_uuid, primary_key: :uuid, dependent: :destroy
  has_many :centralized_scores, class_name: 'Score', foreign_key: :survey_id, dependent: :destroy
  has_many :distributed_scores, class_name: 'Score', foreign_key: :survey_uuid, dependent: :destroy
  has_one :survey_export

  acts_as_paranoid
  has_paper_trail on: %i[update destroy]
  delegate :project, to: :instrument
  validates :device_id, presence: true, allow_blank: false
  validates :uuid, presence: true, allow_blank: false
  validates :instrument_id, presence: true, allow_blank: false
  paginates_per 50
  after_create :calculate_percentage
  after_commit :schedule_export, if: proc { |survey| survey.instrument.auto_export_responses }
  scope :non_roster, -> { where(roster_uuid: nil) }

  def identifier
    question = instrument.questions.where(identifies_survey: true).first
    response = responses.where(question_identifier: question.question_identifier).first if question
    response&.text
  end

  def schedule_export
    job = Sidekiq::ScheduledSet.new.find do |entry|
      entry.item['class'] == 'ExportWorker' && entry.item['args'].first == instrument_id
    end
    return if job

    DateTime.now.hour < 12 ? ExportWorker.perform_at(DateTime.now.at_noon, instrument_id) : ExportWorker.perform_at(DateTime.now.tomorrow.at_noon, instrument_id)
  end

  def switch_instrument(destination_instrument_id)
    destination_instrument = Instrument.find(destination_instrument_id)
    return unless destination_instrument

    saved = update_attributes(instrument_id: destination_instrument.id, instrument_version_number: destination_instrument.current_version_number)
    if saved
      responses.each do |response|
        destination_question = destination_instrument.questions.where(question_identifier: "#{response.question_identifier}_#{destination_instrument.project_id}").try(:first)
        next unless destination_question

        response.update_attributes(question_identifier: destination_question.question_identifier, question_id: destination_question.id)
      end
    end
  end

  def scores
    Score.where('survey_id = ? OR survey_uuid = ?', id, uuid)
  end

  def calculate_percentage
    job = Sidekiq::ScheduledSet.new.find do |entry|
      entry.item['class'] == 'SurveyPercentWorker' && entry.item['args'].first == id
    end
    SurveyPercentWorker.perform_in(5.hours, id) unless job
  end

  # TODO: Re-implement
  def calculate_completion_rate
    valid_response_count = responses.where.not('text = ? AND other_response = ? AND special_response = ?', nil || '', nil || '', nil || '').pluck(:uuid).uniq.count
    valid_question_count = instrument_questions.count
    rate = (valid_response_count.to_f / valid_question_count.to_f).round(2) if valid_response_count && valid_question_count && valid_question_count != 0
    update_columns(completion_rate: rate.to_s) if rate
  end

  def location
    "#{latitude} / #{longitude}" if latitude && longitude
  end

  def group_responses_by_day
    responses.group_by_day(:created_at).count
  end

  def group_responses_by_hour
    responses.group_by_hour_of_day(:created_at).count
  end

  def instrument_version
    instrument.version_by_version_number(instrument_version_number)
  end

  def location_link
    "https://www.google.com/maps/place/#{latitude}+#{longitude}" if latitude && longitude
  end

  def metadata
    JSON.parse(read_attribute(:metadata)) unless read_attribute(:metadata).blank?
  end

  def center_id
    metadata['Center ID'] if metadata
  end

  def participant_id
    metadata['Participant ID'] if metadata
  end

  def caregiver_id
    metadata['Caregiver ID'] if metadata
  end

  def label
    metadata['survey_label'] if metadata
  end

  def question_by_identifier(question_identifier)
    iq = instrument.instrument_questions.with_deleted.where(identifier: question_identifier).first
    if iq.nil?
      if question_identifier.count('_') > 2
        first = question_identifier.index('_')
        last = question_identifier.rindex('_')
        id = question_identifier[first + 1...last]
        iq = instrument.instrument_questions.with_deleted.where(identifier: id).first
      else
        ids = question_identifier.split('_')
        iq = instrument.instrument_questions.with_deleted.where(identifier: ids[1]).first
      end
    end
    iq&.question
  end

  def option_labels(response)
    vq = question_by_identifier(response.question_identifier)
    return '' if vq.nil? || !vq.options?

    labels = []
    if Settings.list_question_types.include?(vq.question_type)
      labels << vq.options.map(&:text)
    else
      response.text.split(Settings.list_delimiter).each do |option_index|
        labels << if vq.other? && option_index.to_i == vq.other_index
                    'Other'
                  else
                    label_text(vq, option_index)
                  end
      end
    end
    labels.join(Settings.list_delimiter)
  end

  def label_text(versioned_question, option_index)
    versioned_question.options[option_index.to_i].try(:text)
  end

  def sanitize(str)
    sanitizer = Rails::Html::FullSanitizer.new
    sanitizer.sanitize(str)
  end

  def write_short_row
    rows = []
    responses.each do |response|
      row = Rails.cache.fetch("w_s_r-#{instrument_id}-#{instrument_version_number}-#{id}-#{updated_at}-#{response.id}-#{response.updated_at}", expires_in: 30.minutes) do
        [identifier, id, response.question_identifier, sanitize(question_by_identifier(response.question_identifier).try(:text)), response.text, option_labels(response),
         response.special_response, response.other_response]
      end
      row.map! { |item| item || '' }
      rows << row
    end
    survey_export.update(short: rows.to_s, last_response_at: responses.pluck(:updated_at).max)
  end

  def validation_identifier
    return unless metadata

    metadata['Center ID'] || metadata['Participant ID']
  end

  def start_time
    Rails.cache.fetch("start-time-#{id}-#{updated_at}", expires_in: 30.minutes) do
      responses.where.not(time_started: nil).order('time_started ASC').try(:first).try(:time_started)
    end
  end

  def end_time
    Rails.cache.fetch("end-time-#{id}-#{updated_at}", expires_in: 30.minutes) do
      responses.where.not(time_ended: nil).order('time_ended DESC').try(:first).try(:time_ended)
    end
  end

  def survey_duration
    end_time - start_time if end_time && start_time
  end

  def write_wide_row
    headers =
      Rails.cache.fetch("w_w_r_h-#{instrument_id}-#{instrument_version_number}", expires_in: 30.minutes) do
        array = instrument.wide_headers
        Hash[array.map.with_index.to_a]
      end
    row = [id, uuid, device&.identifier, device_label || device.label, latitude,
           longitude, instrument_id, instrument_version_number, instrument_title,
           start_time&.to_s, end_time&.to_s, survey_duration]

    metadata&.each do |k, v|
      row[headers[k]] = v
    end

    responses.each do |response|
      identifier_index = headers["q_#{response.question_identifier}"]
      row[identifier_index] = response.text if identifier_index
      short_qid_index = headers["q_#{response.question_identifier}_short_qid"]
      row[short_qid_index] = response.question_id if short_qid_index
      question_type_index = headers["q_#{response.question_identifier}_question_type"]
      row[question_type_index] = question_by_identifier(response.question_identifier).try(:question_type) if question_type_index
      special_identifier_index = headers["q_#{response.question_identifier}_special"]
      row[special_identifier_index] = response.special_response if special_identifier_index
      other_identifier_index = headers["q_#{response.question_identifier}_other"]
      row[other_identifier_index] = response.other_response if other_identifier_index
      label_index = headers["q_#{response.question_identifier}_label"]
      row[label_index] = option_labels(response) if label_index
      question_version_index = headers["q_#{response.question_identifier}_version"]
      row[question_version_index] = response.question_version if question_version_index
      question_text_index = headers["q_#{response.question_identifier}_text"]
      row[question_text_index] = sanitize(question_by_identifier(response.question_identifier).try(:text)) if question_text_index
      start_time_index = headers["q_#{response.question_identifier}_start_time"]
      row[start_time_index] = response.time_started&.to_s if start_time_index
      end_time_index = headers["q_#{response.question_identifier}_end_time"]
      row[end_time_index] = response.time_ended&.to_s if end_time_index
    end
    device_user_id_index = headers['device_user_id']
    device_user_username_index = headers['device_user_username']
    device_user_ids = Rails.cache.fetch("d_u_i-#{id}-#{updated_at}-#{responses.maximum('updated_at')}") do
      responses.pluck(:device_user_id).uniq.compact
    end
    unless device_user_ids.empty?
      row[device_user_id_index] = device_user_ids.join(',')
      row[device_user_username_index] = DeviceUser.find(device_user_ids).map(&:username).uniq.join(',')
    end
    row.map! { |item| item || '' }
    survey_export.update(wide: row.to_s, last_response_at: responses.pluck(:updated_at).max)
  end

  def write_long_row
    headers = Rails.cache.fetch("w_l_r_h-#{instrument_id}-#{instrument_version_number}", expires_in: 30.minutes) do
      array = instrument.long_headers
      Hash[array.map.with_index.to_a]
    end
    csv = []
    responses.each do |response|
      row = Rails.cache.fetch("w_l_r-#{instrument_id}-#{instrument_version_number}-#{id}-#{updated_at}-#{response.id}
        -#{response.updated_at}", expires_in: 30.minutes) do
        ["q_#{response.question_identifier}", "q_#{response.question_id}", instrument_id,
         response.instrument_version_number, response.question_version, instrument_title, id,
         response.survey_uuid, device_id, device_uuid, device_label,
         question_by_identifier(response.question_identifier).try(:question_type),
         sanitize(question_by_identifier(response.question_identifier).try(:text)),
         response.text, option_labels(response), response.special_response,
         response.other_response, response.time_started&.to_s, response.time_ended&.to_s,
         response.device_user.try(:id), response.device_user.try(:username),
         start_time&.to_s, end_time&.to_s, survey_duration]
      end
      metadata&.each do |k, v|
        row[headers[k]] = v if headers[k]
      end
      row.map! { |item| item || '' }
      csv << row
    end
    survey_export.update(long: csv.to_s, last_response_at: responses.pluck(:updated_at).max)
  end

  def score
    scheme = instrument.score_schemes.first
    scheme.score_survey(self)
  end

  def response_for_question(question)
    responses.where(question_identifier: question.question_identifier).try(:first)
  end
end
