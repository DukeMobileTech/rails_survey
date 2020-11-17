# frozen_string_literal: true

# == Schema Information
#
# Table name: instruments
#
#  id                         :integer          not null, primary key
#  title                      :string
#  created_at                 :datetime
#  updated_at                 :datetime
#  language                   :string
#  alignment                  :string
#  instrument_questions_count :integer          default(0)
#  project_id                 :integer
#  published                  :boolean
#  deleted_at                 :datetime
#  require_responses          :boolean          default(FALSE)
#  scorable                   :boolean          default(FALSE)
#  auto_export_responses      :boolean          default(TRUE)
#

class Instrument < ActiveRecord::Base
  include Translatable
  include Alignable
  include LanguageAssignable

  serialize :special_options, Array
  scope :published, -> { where(published: true) }
  belongs_to :project, touch: true

  has_many :instrument_questions, dependent: :destroy
  has_many :questions, -> { distinct }, through: :instrument_questions
  has_many :question_translations, through: :questions, source: :translations
  has_many :option_sets, -> { distinct }, through: :questions
  has_many :option_translations, through: :options, source: :translations
  has_many :option_in_option_sets, -> { distinct }, through: :option_sets
  has_many :options, through: :option_in_option_sets
  has_many :displays, -> { order 'position' }, dependent: :destroy
  has_many :display_translations, through: :displays
  has_many :instrument_rules
  has_many :translations, foreign_key: 'instrument_id', class_name: 'InstrumentTranslation', dependent: :destroy
  has_many :surveys
  has_many :responses, through: :surveys
  has_many :response_images, through: :responses
  has_one :response_export
  has_many :sections, dependent: :destroy
  has_many :section_translations, through: :sections, source: :translations
  has_many :rules, through: :instrument_rules
  has_many :grids, dependent: :destroy
  has_many :grid_labels, through: :grids
  has_many :metrics, dependent: :destroy
  has_many :rosters
  has_many :score_schemes, dependent: :destroy
  has_many :randomized_factors, dependent: :destroy
  has_many :randomized_options, through: :randomized_factors
  has_many :next_questions, -> { order 'instrument_questions.number_in_instrument' }, through: :instrument_questions
  has_many :critical_responses, through: :questions
  has_many :loop_questions, through: :instrument_questions

  has_paper_trail
  acts_as_paranoid
  before_save :update_question_count
  after_update :update_special_options
  validates :title, presence: true, allow_blank: false
  validates :project_id, presence: true, allow_blank: false

  def language_name(name = language)
    Settings.languages.to_h.key(name)
  end

  def available_languages
    [language] + question_translations.pluck(:language).uniq
  end

  def self.create_translations
    Instrument.all.each do |instrument|
      languages = instrument.question_translations.pluck(:language).uniq
      languages.each do |translation_language|
        instrument_translation = instrument.translations.where(language: translation_language).first
        unless instrument_translation
          instrument.translations.create!(language: translation_language, title: instrument.title,
                                          alignment: instrument.alignment)
        end
      end
    end
  end

  def reorder_displays(display_order)
    ActiveRecord::Base.transaction do
      display_order.each_with_index do |value, index|
        display = displays.where(id: value).first
        if display && display.position != index + 1
          display.position = index + 1
          display.save!
        end
      end
      reload
      renumber_questions
    end
  end

  def set_skip_patterns
    ActiveRecord::Base.transaction do
      SkipPattern.all.each do |pattern|
        nq = next_questions.where(
          option_identifier: pattern.option_identifier,
          question_identifier: pattern.question_identifier,
          next_question_identifier: pattern.next_question_identifier
        ).first
        next if nq

        iq = instrument_questions.where(identifier: pattern.question_identifier).first
        niq = instrument_questions.where(identifier: pattern.next_question_identifier).first
        oi_present = iq.options.pluck(:identifier).include?(pattern.option_identifier) if iq && niq
        next unless oi_present

        NextQuestion.create!(
          option_identifier: pattern.option_identifier,
          question_identifier: pattern.question_identifier,
          next_question_identifier: pattern.next_question_identifier,
          instrument_question_id: iq.id
        )
      end
    end
  end

  def copy(project, display)
    instrument_copy = dup
    instrument_copy.project_id = project.id
    instrument_copy.title = title + "_#{Time.now.to_i}"
    instrument_copy.save!
    ActiveRecord::Base.transaction do
      if display == 'AS_IT_IS'
        displays.each do |display|
          display_copy = display.dup
          display_copy.instrument_id = instrument_copy.id
          display_copy.save!
          display.instrument_questions.order(:number_in_instrument).each do |iq|
            iq.copy(display_copy.id, instrument_copy.id)
          end
        end
      elsif display == 'ONE_QUESTION_PER_SCREEN'
        index = 0
        instrument_questions.order(:number_in_instrument).each do |iq|
          index += 1
          display_copy = Display.create!(mode: 'SINGLE', position: index, instrument_id: instrument_copy.id, title: index.to_s)
          iq.copy(display_copy.id, instrument_copy.id)
        end
      elsif display == 'ALL_QUESTIONS_ON_ONE_SCREEN'
        display_copy = Display.create!(mode: 'MULTIPLE', position: 1, instrument_id: instrument_copy.id, title: 'Questions')
        instrument_questions.order(:number_in_instrument).each do |iq|
          iq.copy(display_copy.id, instrument_copy.id)
        end
      end
    end
    instrument_copy
  end

  def renumber_questions
    ActiveRecord::Base.transaction do
      position = 1
      displays.each do |display|
        display.instrument_questions.each do |iq|
          if iq.number_in_instrument != position
            iq.number_in_instrument = position
            iq.save!
          end
          position += 1
        end
      end
    end
  end

  def delete_duplicate_surveys
    grouped_surveys = surveys.group_by(&:uuid)
    grouped_surveys.values.each do |duplicates|
      duplicates.shift
      duplicates.map(&:delete)
    end
  end

  def update_special_options
    if special_options != special_options_was
      deleted_special_options = special_options_was - special_options
      options.special_options.where(text: deleted_special_options).delete_all unless deleted_special_options.blank?
      new_special_options = special_options - special_options_was
      questions.each(&:create_special_options) if !new_special_options.blank? && !questions.blank?
    end
  end

  def version_by_version_number(version_number)
    return nil if version_number > versions.size || version_number <= 0

    versions[version_number - 1].reify
  end

  def completion_rate
    sum = 0.0
    surveys.each do |survey|
      sum += survey.completion_rate.to_f if survey.completion_rate
    end
    (sum / surveys.count).round(2)
  end

  def current_version_number
    versions.count
  end

  def question_count
    instrument_questions.count
  end

  def survey_instrument_versions
    surveys.pluck(:instrument_version_number).uniq
  end

  def to_csv
    CSV.generate do |csv|
      export(csv)
    end
  end

  def export(format)
    sanitizer = Rails::Html::FullSanitizer.new
    format << ['Instrument id:', id]
    format << ['Instrument title:', title]
    format << ['Version number:', current_version_number]
    format << ['Language:', language]
    format << ["\n"]
    format << %w[number_in_instrument question_identifier question_type question_instructions question_text] + instrument_translation_languages
    questions.each do |question|
      format << [question.number_in_instrument, question.question_identifier, question.question_type, sanitizer.sanitize(question.instructions), sanitizer.sanitize(question.text)] + translations_for_object(question)
      question.options.each do |option|
        format << ['', '', '', "Option for question #{question.question_identifier}", option.text] + translations_for_object(option)
        next unless option.skips

        option.skips.each do |skip|
          format << ['', '', '', "For option #{option.text}, SKIP question", skip.question_identifier]
        end
      end
      if question.reg_ex_validation_message
        format << ['', '', '', "Regular expression failure message for #{question.question_identifier}",
                   question.reg_ex_validation_message]
      end
      format << ['', '', '', 'Question identifies survey', 'YES'] if question.identifies_survey
    end
  end

  def instrument_translation_languages
    translation_languages = []
    translations.each do |t_language|
      translation_languages << t_language.language
    end
    translation_languages
  end

  def translations_for_object(obj)
    sanitizer = Rails::Html::FullSanitizer.new
    text_translations = []
    obj.translations.each do |translation|
      text_translations << sanitizer.sanitize(translation.text) if instrument_translation_languages.include? translation.language
    end
    text_translations
  end

  def update_instrument_version
    # Force update for paper trail
    increment!(:child_update_count)
  end

  def reorder_questions(old_number, new_number)
    ActiveRecord::Base.transaction do
      # If question is moved up in instrument, settle conflicts by giving the
      # most recently updated (ie the moved question) the lower number.
      question_moved_up = old_number > new_number
      secondary_order = question_moved_up ? 'DESC' : 'ASC'

      questions.unscoped.where('instrument_id = ? AND deleted_at is null', id).order("number_in_instrument ASC, updated_at #{secondary_order}").each_with_index do |question, index|
        updated_number = index + 1
        if question.number_in_instrument != updated_number
          question.number_in_instrument = updated_number
          question.save
        end
      end
    end
  end

  def reorder_questions_after_delete(question_number)
    ActiveRecord::Base.transaction do
      questions.unscoped.where('instrument_id = ? AND number_in_instrument >= ? AND deleted_at is null', id, question_number).each_with_index do |question, _index|
        question.number_in_instrument = question.number_in_instrument - 1
        question.save
      end
    end
  end

  def translation_csv_template
    CSV.generate do |csv|
      generate_row(csv)
    end
  end

  def generate_row(csv)
    sanitizer = Rails::Html::FullSanitizer.new
    csv << ['instrument_id', id]
    csv << ['translation_language_iso_code', '', 'Enter language ISO 639-1 code in column 2']
    csv << ['language_alignment', '', 'Enter left in column 2 if words in the language are read left-to-right or right if they are read right-to-left']
    csv << ['instrument_title', sanitizer.sanitize(title), '', 'Enter instrument_title translation in column 3']
    csv << ['']
    csv << ['question_identifier',	'question_text',	'Enter question_text translations in this column',	'instructions',	'Enter instructions translations in this column',	'reg_ex_validation_message',	'Enter reg_ex_validation_message translations in this column']
    questions.each do |question|
      csv << [question.question_identifier, sanitizer.sanitize(question.text), '', sanitizer.sanitize(question.instructions), '', sanitizer.sanitize(question.reg_ex_validation_message), '']
    end
    csv << ['']
    csv << ['option_id',	'option_text',	'Enter option_text translation in this column']
    options.regular.each do |option|
      csv << [option.id, sanitizer.sanitize(option.text), '']
    end
    csv << ['']
    csv << ['section_id',	'section_title_text',	'Enter section_title_text translation in this column']
    sections.each do |section|
      csv << [section.id, sanitizer.sanitize(section.title), '']
    end
  end

  def export_surveys
    unless response_export
      ResponseExport.create(instrument_id: id, instrument_versions: survey_instrument_versions)
      reload
    end
    response_export.update_attributes(completion: 0.0)
    write_export_rows
  end

  def write_export_rows
    surveys.each do |survey|
      SurveyExportWorker.perform_async(survey.uuid)
    end
    StatusWorker.perform_in(10.seconds, response_export.id)
  end

  def short_headers
    %w[identifier survey_id question_identifier question_text response_text
       response_label special_response other_response]
  end

  def long_headers
    %w[question_identifier short_qid instrument_id instrument_version_number question_version_number
       instrument_title survey_id survey_uuid device_id device_uuid device_label
       question_type question_text response response_labels special_response
       other_response response_time_started response_time_ended device_user_id
       device_user_username survey_start_time survey_end_time duration_in_seconds] + metadata_keys
  end

  def create_loop_question(lq, variable_identifiers, question_identifier_variables, idx)
    identifier = "#{lq.parent}_#{lq.looped}_#{idx}"
    variable_identifiers << identifier unless variable_identifiers.include? identifier
    question_identifier_variables.each do |variable|
      variable_identifiers << identifier + variable unless variable_identifiers.include? identifier + variable
    end
  end

  def wide_headers
    variable_identifiers = []
    question_identifier_variables = %w[_short_qid _question_type _label _special
                                       _other _version _text _start_time _end_time]
    iqs = Rails.cache.fetch("instrument-questions-#{id}-#{instrument_questions.maximum('updated_at')}",
                            expires_in: 30.minutes) do
      instrument_questions.order(:number_in_instrument)
    end
    iqs.each do |iq|
      if !iq.loop_questions.empty?
        iq.loop_questions.each do |lq|
          if iq.question.question_type == 'INTEGER'
            (1..12).each do |n|
              create_loop_question(lq, variable_identifiers, question_identifier_variables, n)
            end
          else
            if !lq.option_indices.blank?
              lq.option_indices.split(',').each do |ind|
                create_loop_question(lq, variable_identifiers, question_identifier_variables, ind)
              end
            else
              iq.question.options.each_with_index do |_option, idx|
                create_loop_question(lq, variable_identifiers, question_identifier_variables, idx)
              end
            end
          end
        end
      else
        variable_identifiers << iq.identifier unless variable_identifiers.include? iq.identifier
        question_identifier_variables.each do |variable|
          variable_identifiers << iq.identifier + variable unless variable_identifiers.include? iq.identifier + variable
        end
      end
    end
    variable_identifiers.map! { |identifier| "q_#{identifier}" }
    %w[survey_id survey_uuid device_identifier device_label latitude longitude
       instrument_id instrument_version_number instrument_title survey_start_time
       survey_end_time duration_in_seconds device_user_id device_user_username] + metadata_keys + variable_identifiers
  end

  def metadata_keys
    Rails.cache.fetch("survey-metadata-#{id}-#{surveys.maximum('updated_at')}", expires_in: 30.minutes) do
      m_keys = []
      surveys.each do |survey|
        next unless survey.metadata

        survey.metadata.keys.each do |key|
          m_keys << key unless m_keys.include? key
        end
      end
      m_keys
    end
  end

  def reorder_display_text
    sanitizer = Rails::Html::FullSanitizer.new
    text = ''
    questions.each do |question|
      text << "#{question.question_identifier}\t#{question.number_in_instrument}\t#{sanitizer.sanitize(question.text).truncate(50)}\n"
    end
    text
  end

  def mass_question_reorder(q_str)
    # Parse question identifiers from string parameter
    reordered_questions = q_str.strip.split("\n")
    question_identifiers = []
    reordered_questions.each do |question_line|
      question_identifiers << question_line.split("\t")[0]
    end
    # Keep valid question identifiers
    db_question_identifiers = questions.pluck(:question_identifier)
    real_qids = question_identifiers.select { |qid| db_question_identifiers.include?(qid) }
    # Delete removed questions
    db_question_identifiers.each do |qid|
      questions.where(question_identifier: qid).try(:first).try(:destroy) unless real_qids.include?(qid)
    end
    # Update positions of reordered questions
    real_qids.each_with_index do |qid, index|
      question = questions.where(question_identifier: qid).first
      question&.update_attribute(:number_in_instrument, index + 1)
    end
  end

  def reorder(order)
    ActiveRecord::Base.transaction do
      reordered_displays = order.strip.split("\n\n")
      display_position = 1
      number_in_instrument = 1
      preserved_displays = []
      preserved_questions = []
      reordered_displays.each do |dis|
        display_string = dis.split(/: /, 2)
        display = displays.find(display_string[0].to_i)
        display&.update_attribute(:position, display_position)
        display_position += 1
        preserved_displays << display
        display_and_questions = display_string[1].split(/\n\t/)
        display_and_questions.drop(1).each do |qid|
          iq = instrument_questions.where(identifier: qid).first
          iq&.update_attribute(:number_in_instrument, number_in_instrument)
          number_in_instrument += 1
          preserved_questions << iq
        end
      end
      (displays - preserved_displays).each(&:destroy)
      (instrument_questions - preserved_questions).each(&:destroy)
    end
  end

  private

  def update_question_count
    self.previous_question_count = questions.count
  end
end
