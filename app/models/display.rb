# frozen_string_literal: true

# == Schema Information
#
# Table name: displays
#
#  id                         :integer          not null, primary key
#  position                   :integer
#  instrument_id              :integer
#  created_at                 :datetime
#  updated_at                 :datetime
#  title                      :string
#  deleted_at                 :datetime
#  section_id                 :integer
#  instrument_questions_count :integer
#  instrument_position        :integer
#

class Display < ApplicationRecord
  belongs_to :instrument, touch: true
  belongs_to :section, touch: true
  has_many :instrument_questions, -> { order 'position' }, dependent: :destroy
  has_many :display_instructions, dependent: :destroy
  has_many :display_translations, dependent: :destroy

  acts_as_paranoid
  has_paper_trail
  acts_as_list scope: :section

  validates :instrument_id, presence: true
  validates :section_id, presence: true
  validates :title, presence: true, uniqueness: { scope: [:section_id] }

  def copy(instrument, display_type)
    if display_type == 'AS_IT_IS'
      copy = dup
      copy.instrument_id = instrument.id
      copy.position = instrument.displays.size + 1
      copy.save!
      instrument_questions.each do |iq|
        iq.copy(copy.id, instrument.id)
      end
    elsif display_type == 'ONE_QUESTION_PER_SCREEN'
      instrument_questions.order(:number_in_instrument).each_with_index do |iq, index|
        display_copy = Display.create!(mode: 'SINGLE', position: instrument.displays.size + index, instrument_id: instrument.id, title: "#{title}_#{index}")
        iq.copy(display_copy.id, instrument.id)
      end
    end
  end

  def move(destination_display_id, moved)
    destination = instrument.displays.where(id: destination_display_id).first
    if destination_display_id == -1
      destination = instrument.displays.create!(title: 'New Display',
                                                position: instrument.displays.size + 1, mode: 'MULTIPLE')
    end
    if destination && moved
      moved.each do |id|
        iq = instrument_questions.find(id)
        iq.display_id = destination.id
        iq.save!
      end
    end
    destination
  end

  def translated_text(language)
    return title if language == instrument.language

    translation = display_translations.where(language: language).first
    translation&.text ? translation.text : title
  end

  def standardize_tables
    instrument_questions.group_by(&:table_identifier).each do |t_id, iq|
      next unless t_id
      next if iq.size <= 5

      sets = iq.each_slice(5).to_a
      sets.each_with_index do |iq_set, index|
        instrument_questions.where(id: iq_set.map(&:id)).update_all(table_identifier: "#{t_id} #{index}", updated_at: Time.now)
      end
      touch
    end
  end

  def order_instrument_questions(order)
    ActiveRecord::Base.transaction do
      order.each_with_index do |value, index|
        instrument_question = instrument_questions.where(id: value).first
        instrument_question.update_columns(position: index + 1) if instrument_question && instrument_question.position != index + 1
      end
    end
    reload
    instrument.order_instrument_questions
  end
end
