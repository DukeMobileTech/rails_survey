# frozen_string_literal: true

# == Schema Information
#
# Table name: options
#
#  id                        :integer          not null, primary key
#  text                      :text
#  created_at                :datetime
#  updated_at                :datetime
#  deleted_at                :datetime
#  instrument_version_number :integer          default(-1)
#  identifier                :string
#

class Option < ActiveRecord::Base
  include Translatable
  has_many :option_in_option_sets, dependent: :destroy
  has_many :option_sets, through: :option_in_option_sets
  has_many :translations, foreign_key: 'option_id', class_name: 'OptionTranslation', dependent: :destroy
  has_many :skip_patterns, foreign_key: 'option_identifier', dependent: :destroy
  has_paper_trail
  acts_as_paranoid

  validates :text, presence: true, allow_blank: false
  validates :identifier, presence: true, uniqueness: true

  def translated(code)
    trans = translations.where(language: code)
    "<ul>#{trans.map { |translation| "<li>#{translation.text}</li>" }.join}</ul>" unless trans.empty?
  end

  def option_set_titles
    "<ul>#{option_sets.map { |os| "<li>#{os.title}</li>" }.join}</ul>" unless option_sets.empty?
  end

  def option_set_title_lines
    option_sets.map(&:title).join("\, ") unless option_sets.empty?
  end

  def translated_lines(code)
    trans = translations.where(language: code)
    sanitizer = Rails::Html::FullSanitizer.new
    trans.map { |translation| sanitizer.sanitize translation.text }.join("\, ") unless trans.empty?
  end

  def self.export
    CSV.generate do |csv|
      csv << %w[identifier option_sets english swahili amharic khmer]
      Option.all.each do |option|
        csv << [option.identifier, option.option_set_title_lines, option.text,
                option.translated_lines('sw'), option.translated_lines('am'), option.translated_lines('km')]
      end
    end
  end

  def translated_text(language, instrument)
    return text if language == instrument.language

    translation = translations.where(language: language).first
    translation&.text ? translation.text : text
  end

  def to_option_in_option_set
    return unless id || option_set_id || number_in_question

    OptionInOptionSet.create!(option_id: id, option_set_id: option_set_id,
                              number_in_question: number_in_question)
  end

  def to_s
    text
  end

  # TODO: Doesn't work anymore
  def instrument_version
    if instrument && (read_attribute(:instrument_version_number) == -1)
      instrument.current_version_number
    else
      read_attribute(:instrument_version_number)
    end
  end

  def update_option_translation(status = true)
    translations.each do |translation|
      translation.update_attribute(:option_changed, status)
    end
  end

  private

  def update_instrument_version
    return unless instrument || question

    instrument.update_instrument_version
    question.update_question_version
    question.update_column(:instrument_version_number, instrument.current_version_number)
  end

  def record_instrument_version_number
    update_column(:instrument_version_number, instrument.current_version_number)
    question.update_column(:instrument_version_number, instrument.current_version_number)
  end
end
