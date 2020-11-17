# frozen_string_literal: true

# == Schema Information
#
# Table name: instrument_questions
#
#  id                       :integer          not null, primary key
#  question_id              :integer
#  instrument_id            :integer
#  number_in_instrument     :integer
#  display_id               :integer
#  created_at               :datetime
#  updated_at               :datetime
#  identifier               :string
#  deleted_at               :datetime
#  table_identifier         :string
#  loop_questions_count     :integer          default(0)
#  carry_forward_identifier :string
#  position                 :integer
#  skip_operation           :string
#

class InstrumentQuestion < ActiveRecord::Base
  belongs_to :instrument, touch: true
  belongs_to :question
  belongs_to :display, touch: true, counter_cache: true
  has_many :next_questions, dependent: :destroy
  has_many :multiple_skips, dependent: :destroy
  has_many :follow_up_questions, dependent: :destroy
  has_many :condition_skips, dependent: :destroy
  has_many :translations, through: :question
  has_many :back_translations, through: :translations
  has_many :display_instructions, dependent: :destroy
  has_many :loop_questions, dependent: :destroy
  has_many :all_loop_questions, -> { with_deleted }, class_name: 'LoopQuestion'
  has_many :critical_responses, through: :question

  acts_as_paranoid
  has_paper_trail
  acts_as_taggable
  acts_as_taggable_on :countries

  validates :identifier, presence: true, uniqueness: { scope: :instrument_id, message: 'instrument already has this identifier' }

  after_update :update_display_instructions, if: :number_in_instrument_changed?
  after_destroy :renumber_questions

  def country_specific(language)
    return false if language == 'en' || country_list.blank?

    return !country_list.include?('cambodia') if language == 'km'
    return !country_list.include?('ethiopia') if language == 'am'
    return !country_list.include?('kenya') if language == 'sw'
  end

  def letters
    ('a'..'z').to_a
  end

  def hashed_options
    hash = {}
    non_special_options.each do |option|
      hash[option.identifier] = option
    end
    hash
  end

  def options
    non_special_options + special_options
  end

  def question_type
    question.question_type
  end

  def text
    question.text
  end

  def translated_text(language)
    return question.text if language == instrument.language

    translation = question.translations.where(language: language).first
    translation&.text ? translation.text : question.text
  end

  def before_text_instruction
    question.instruction&.text
  end

  def after_text_instruction
    question.after_text_instruction&.text
  end

  def pop_up_instruction_text
    question.pop_up_instruction&.text
  end

  def display_title
    display&.title
  end

  def section_title
    display&.section&.title
  end

  def loop_string
    return if loop_questions.blank?

    skipped = +''
    loop_questions.each do |loop_question|
      q = instrument.instrument_questions.where(identifier: loop_question.looped).first
      skipped << "<b>##{q.number_in_instrument}</b>, "
    end
    "-> Ask questions #{skipped.strip.chop} for each of the responses"
  end

  def multiple_skip_string
    skip_hash = Hash.new { |hash, key| hash[key] = [] }
    multiple_skips.group_by(&:option_identifier).each do |option_identifier, skips|
      option = hashed_options[option_identifier]
      skipped_questions = skips.map { |ms| ms.skipped_question&.number_in_instrument }
      skipped_questions = skipped_questions.compact.uniq.sort
      skipped_questions = to_ranges(skipped_questions)
      skipped = skipped_questions.inject(+'') do |str, que|
        str << if que.first == que.last
                 "<b>##{que.first}</b>, "
               else
                 "<b>##{que.first}-#{que.last}</b>, "
               end
      end
      key = if option
              index = non_special_options.index(option)
              "(#{letters[index]})"
            elsif option_identifier.nil?
              "(#{skips.map(&:value).uniq.join(',')})"
            else
              option_identifier
            end
      skip_hash[skipped.strip.chop] << key
    end
    mss = +''
    skip_hash.each do |key, values|
      str = +'<div>* If '
      values.each do |value|
        str << "<b>#{value}</b> or "
      end
      str = str.strip.chop.chop << "skip questions: #{key} </div>"
      mss << str
    end
    mss
  end

  def to_ranges(array)
    ranges = []
    unless array.empty?
      left = array.first
      right = nil
      array.each do |obj|
        if right && obj != right.succ
          ranges << Range.new(left, right)
          left = obj
        end
        right = obj
      end
      ranges << Range.new(left, right)
    end
    ranges
  end

  def next_question_string(the_next_questions)
    skip_to = +'=> If '
    the_next_questions.each do |next_question|
      option = hashed_options[next_question.option_identifier]
      if option
        index = non_special_options.index(option)
        skip_to << "<b>(#{letters[index]})</b> or "
      elsif next_question.value
        skip_to << "<b>#{next_question.value}</b> or "
      else
        skip_to << "<b>#{next_question.option_identifier}</b> or "
      end
    end
    "#{skip_to.strip.chop.chop} go to <b>##{next_questions&.first&.skip_to_question&.number_in_instrument}</b>"
  end

  def slider_variant?
    question.slider_variant?
  end

  def select_one_variant?
    question.select_one_variant?
  end

  def select_multiple_variant?
    question.select_multiple_variant?
  end

  def list_of_boxes_variant?
    question.list_of_boxes_variant?
  end

  def non_special_options?
    !non_special_options.empty?
  end

  def other?
    question.other?
  end

  def non_special_options
    question.option_set_id ? question.option_set.options : []
  end

  def special_options
    question.special_option_set_id ? question.special_option_set.options : []
  end

  def option_translations
    question.option_set_id ? question.option_set.translations : []
  end

  def option_back_translations
    question.option_set_id ? question.option_set.back_translations : []
  end

  def looped?(l_questions = instrument.loop_questions)
    !l_questions.where(looped: identifier).empty?
  end

  def parent(l_questions = instrument.loop_questions, iqs = instrument.instrument_questions)
    pid = l_questions.where(looped: identifier)&.first&.parent
    iqs.find_by_identifier(pid) if pid
  end

  def copy(display_id, instrument_id)
    iq_copy = dup
    iq_copy.display_id = display_id
    iq_copy.instrument_id = instrument_id
    i = Instrument.find instrument_id
    iq_copy.number_in_instrument = i.instrument_questions.size + 1
    iq_copy.save!
    next_questions.each do |nq|
      nq_copy = nq.dup
      nq_copy.instrument_question_id = iq_copy.id
      nq_copy.save!
    end
    multiple_skips.each do |ms|
      ms_copy = ms.dup
      ms_copy.instrument_question_id = iq_copy.id
      ms_copy.save!
    end
    follow_up_questions.each do |fuq|
      fuq_copy = fuq.dup
      fuq_copy.instrument_question_id = iq_copy.id
      fuq_copy.save!
    end
  end

  private

  def update_display_instructions
    display_instructions.update_all(position: number_in_instrument)
  end

  def renumber_questions
    instrument.renumber_questions
  end
end
