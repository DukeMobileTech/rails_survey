# == Schema Information
#
# Table name: surveys
#
#  id                        :integer          not null, primary key
#  instrument_id             :integer
#  created_at                :datetime
#  updated_at                :datetime
#  uuid                      :string(255)
#  device_id                 :integer
#  instrument_version_number :integer
#  instrument_title          :string(255)
#  device_uuid               :string(255)
#  latitude                  :string(255)
#  longitude                 :string(255)
#  metadata                  :text
#  completion_rate           :decimal(3, 2)
#  device_label              :string(255)
#

class Survey < ActiveRecord::Base
  attr_accessible :instrument_id, :instrument_version_number, :uuid, :device_id, :instrument_title,
    :device_uuid, :latitude, :longitude, :metadata, :completion_rate, :device_label
  belongs_to :instrument
  belongs_to :device
  has_many :responses, foreign_key: :survey_uuid, primary_key: :uuid, dependent: :destroy
  delegate :project, to: :instrument
  validates :device_id, presence: true, allow_blank: false
  validates :uuid, presence: true, allow_blank: false
  validates :instrument_id, presence: true, allow_blank: false
  validates :instrument_version_number, presence: true, allow_blank: false
  paginates_per 50
  
  def percent_complete
    completion_rate || calculate_completion_rate
  end
  
  def calculate_completion_rate
    valid_response_count = responses.where.not('text = ? AND other_response = ? AND special_response = ?',
                            nil || "", nil || "", nil || "").pluck(:question_id).uniq.count
    valid_question_count = instrument.version_by_version_number(instrument_version_number)
                            .questions.select{|question| question.question_type != 'INSTRUCTIONS'}.count
    rate = (valid_response_count.to_f / valid_question_count).round(2) if (valid_response_count &&
          valid_question_count && valid_question_count != 0)
    self.update(completion_rate: rate) if rate
    completion_rate 
  end

  def location
    "#{latitude} / #{longitude}" if latitude and longitude
  end
  
  def group_responses_by_day
    self.responses.group_by_day(:created_at).count 
  end
  
  def group_responses_by_hour
    self.responses.group_by_hour_of_day(:created_at).count
  end

  def instrument_version
    instrument.version_by_version_number(instrument_version_number)
  end

  def location_link
    "https://www.google.com/maps/place/#{latitude}+#{longitude}" if latitude and longitude
  end

  def metadata
    JSON.parse(read_attribute(:metadata)) unless read_attribute(:metadata).nil?
  end
  
  def self.to_csv(csv_file)
    CSV.open(csv_file, "wb") do |csv|
      export(csv)
    end
  end
  
  def self.export(format) 
    variable_identifiers = []
    question_identifier_variables = %w[_short_qid _question_type _label _special _other _version _text _start_time _end_time]
    all.each do |survey|
      survey.instrument.questions.each do |question|
        variable_identifiers << question.question_identifier unless variable_identifiers.include? question.question_identifier
        question_identifier_variables.each do |variable|
          variable_identifiers << question.question_identifier + variable unless variable_identifiers.include? question.question_identifier + variable
        end
      end
    end
    
    metadata_keys = []
    all.each do |survey|
      survey.metadata.keys.each do |key|
        metadata_keys << key unless metadata_keys.include? key
      end if survey.metadata
    end
    
    header = ['survey_id', 'survey_uuid', 'device_identifier', 'device_label', 'latitude', 'longitude', 'instrument_id', 'instrument_version_number', 
      'instrument_title', 'survey_start_time', 'survey_end_time', 'device_user_id', 'device_user_username'] + metadata_keys + variable_identifiers
    format << header
      
    all.each do |survey|
      row = [survey.id, survey.uuid, survey.device.identifier, survey.device_label ? survey.device_label : survey.device.label, survey.latitude, survey.longitude, survey.instrument.id,
        survey.instrument_version_number, survey.instrument.title, survey.responses.order('time_started').try(:first).try(:time_started), 
        survey.responses.order('time_ended').try(:last).try(:time_ended)]     
      
      survey.metadata.each do |k, v|
        key_index = header.index {|h| h == k}
        row[key_index] = v
      end if survey.metadata
      
      survey.responses.each do |response|
        identifier_index = header.index(response.question_identifier)
        row[identifier_index] = response.text if identifier_index
        short_qid_index = header.index(response.question_identifier + '_short_qid')
        row[short_qid_index] = response.question_id if short_qid_index
        question_type_index = header.index(response.question_identifier + '_question_type')
        row[question_type_index] = response.question.question_type if question_type_index
        special_identifier_index = header.index(response.question_identifier + '_special')
        row[special_identifier_index] = response.special_response if special_identifier_index
        other_identifier_index = header.index(response.question_identifier + '_other')
        row[other_identifier_index] = response.other_response if other_identifier_index
        label_index = header.index(response.question_identifier + '_label')
        row[label_index] = survey.option_labels(response) if label_index
        question_version_index = header.index(response.question_identifier + '_version')
        row[question_version_index] = response.question_version if question_version_index
        question_text_index = header.index(response.question_identifier + '_text')
        row[question_text_index] = Sanitize.fragment(survey.chronicled_question(response.question_identifier).try(:text)) if question_text_index
        start_time_index = header.index(response.question_identifier + '_start_time')
        row[start_time_index] = response.time_started if start_time_index
        end_time_index = header.index(response.question_identifier + '_end_time')
        row[end_time_index] = response.time_ended if end_time_index
      end
      device_user_id_index = header.index('device_user_id')
      device_user_username_index = header.index('device_user_username')
      device_user_ids = survey.responses.pluck(:device_user_id).uniq.compact
      unless device_user_ids.empty?
        row[device_user_id_index] = device_user_ids.join(",")
        row[device_user_username_index] = DeviceUser.find(device_user_ids).map(&:username).uniq.join(",")   
      end
      format << row
    end
  end
  
  def chronicled_question(question_identifier)
    @chronicled_question ||= instrument_version.find_question_by(question_identifier: question_identifier)
  end
  
  def option_labels(response)
    labels = [] 
    versioned_question = chronicled_question(response.question_identifier)
    if response.question and versioned_question and versioned_question.has_options? 
      response.text.split(Settings.list_delimiter).each do |option_index|
        (versioned_question.has_other? and option_index.to_i == versioned_question.other_index) ? labels << "Other" : labels << versioned_question.options[option_index.to_i].to_s
      end
    end
    labels.join(Settings.list_delimiter)
  end

  def self.to_short_csv(csv_file)
    CSV.open(csv_file, "wb") do |csv|
      short_export(csv)
    end
  end

  def self.short_export(format)
    header = ['identifier', 'survey_id', 'question_identifier', 'question_text', 'response_text', 'response_label', 'special_response', 'other_response']
    format << header
    all.each do |survey|
      validator = survey.validation_identifier
      survey.responses.each do |response|
        row = [validator, survey.id, response.question_identifier, Sanitize.fragment(survey.chronicled_question(response.question_identifier).try(:text)),
               response.text, response.option_labels, response.special_response, response.other_response]
        format << row
      end
    end
  end

  def validation_identifier
    metadata['Center ID'] ? metadata['Center ID'] : metadata['Participant ID'] if metadata
  end

end
