# frozen_string_literal: true

class SurveyPdf
  include Prawn::View
  include PdfUtils
  include Sanitizer

  def initialize(survey, column_count)
    super()
    @survey = survey
    @responses = survey.responses
    @instrument = survey.instrument
    @loop_questions = @instrument.loop_questions
    @instrument_questions = @instrument.instrument_questions
    @column_count = column_count
    register_fonts
    header
    content
    number_odd_pages
    number_even_pages
  end

  private

  def header
    formatted_text [{ text: 'Title: ', styles: [:bold] }, { text: "#{@survey.instrument_title} ", font: 'Courier' },
                    { text: 'Language: ', styles: [:bold] }, { text: "#{@instrument.language_name(@survey.language)} ", font: 'Courier' },
                    { text: 'Version: ', styles: [:bold] }, { text: "#{@survey.instrument_version_number} ", font: 'Courier' },
                    { text: 'Identifier: ', styles: [:bold] }, { text: "#{@survey.identifier} ", font: 'Courier' }]
    horizontal_rule
    move_down 5
  end

  def content
    column_box([0, cursor], columns: @column_count, width: bounds.width) do
      @instrument.sections.includes(:translations).each do |section|
        section_text = @survey.language == @instrument.language ? section.title : section.translations.where(language: @survey.language)&.first&.text
        section_text ||= section.title
        format_section_text(section_text)
        section.displays.includes(:display_translations).each do |display|
          display_text = if @survey.language == @instrument.language
                           display.title
                         else
                           display.display_translations.where(language: @survey.language)&.first&.text
                         end
          display_text ||= display.title
          format_display_text(display_text)
          display.instrument_questions.includes(:loop_questions, question:
            [:translations, { option_set: [instruction: [:instruction_translations], options: [:translations]],
                              instruction: [:instruction_translations] }]).each do |iq|
            # , after_text_instruction: [:instruction_translations], pop_up_instruction: [:instruction_translations] }]).each do |iq|
            if iq.looped?(@loop_questions)
              parent = iq.parent(@loop_questions, @instrument_questions)
              flq = parent&.loop_questions.min_by(&:looped_position)
              if parent&.select_multiple_variant? && flq&.looped_position == iq.number_in_instrument
                response = @responses.find_by_question_identifier(parent.identifier)
                response.text&.split(Settings.list_delimiter)&.each do |res|
                  parent.loop_questions.sort_by(&:looped_position).each do |lq|
                    identifier = "#{parent.identifier}_#{lq.looped}_#{res}"
                    l_response = @responses.find_by_question_identifier(identifier)
                    liq = @instrument_questions.find_by_identifier(lq.looped)
                    liq.identifier = "#{identifier} (#{full_sanitizer.sanitize(parent.non_special_options[res.to_i].to_s)})"
                    write_question(liq, l_response)
                  end
                end
              end
            else
              response = @responses.find_by_question_identifier(iq.identifier)
              write_question(iq, response)
            end
          end
        end
      end
    end
  end

  def write_question(iq, response)
    text "<b>#{iq.number_in_instrument})</b> <i>#{iq.identifier}</i>", inline_format: true
    ins = iq.question.instruction
    if ins
      ins_text = if @survey.language == @instrument.language
                   ins.text
                 else
                   ins.instruction_translations.where(language: @survey.language)&.first&.text
                 end
      ins_text ||= ins.text
      text sanitize_text("<i>#{ins_text}</i>"), color: '808080', inline_format: true if ins_text
    end
    q_text = if @survey.language == @instrument.language
               iq.text
             else
               iq.question.translations.where(language: @survey.language)&.first&.text
             end
    q_text ||= iq.text
    text sanitize_text(q_text), inline_format: true
    if iq.question.respond_to?(:pop_up_instruction)
      pop_ins = iq.question.pop_up_instruction
      if pop_ins
        pop_ins_text = if @survey.language == @instrument.language
                         pop_ins.text
                       else
                         pop_ins.instruction_translations.where(language: @survey.language)&.first&.text
                       end
        pop_ins_text ||= pop_ins.text
        text sanitize_text("<i><sup>*</sup>#{pop_ins_text}</i>"), color: '808080', inline_format: true if pop_ins_text
      end
    end
    if iq.question.respond_to?(:after_text_instruction)
      at_ins = iq.question.after_text_instruction
      if at_ins
        at_ins_text = if @survey.language == @instrument.language
                        at_ins.text
                      else
                        at_ins.instruction_translations.where(language: @survey.language)&.first&.text
                      end
        at_ins_text ||= at_ins.text
        text sanitize_text("<i>#{at_ins_text}</i>"), color: '808080', inline_format: true if at_ins_text
      end
    end
    indent(20) do
      o_ins = iq.question.option_set&.instruction
      if o_ins
        o_ins_text = if @survey.language == @instrument.language
                       o_ins.text
                     else
                       o_ins.instruction_translations.where(language: @survey.language)&.first&.text
                     end
        o_ins_text ||= o_ins.text
        pad(2) { text sanitize_text("<i>#{o_ins_text}</i>"), style: :italic, color: '808080', inline_format: true } if o_ins_text
      end
      font('Courier') do
        if iq.question.option_set
          if iq.question.other? && response&.text&.blank? && !response&.other_response&.blank?
            text "#{@survey.language == 'es' ? 'Otra ' : 'Other '}  #{response&.other_response}"
          end
          unless response&.text.blank?
            CSV.parse(response&.text)[0]&.each_with_index do |res, index|
              if iq.question.other? && res.to_i == iq.question.other_index
                o_text = @survey.language == 'es' ? 'Otra ' : 'Other '
                text "#{o_text}  #{response&.other_response}"
              else
                if iq.question.list_of_boxes_variant?
                  o_text = if @survey.language == @instrument.language
                             iq.question.options[index].to_s
                           else
                             iq.question.options[index].translations.where(language: @survey.language)&.first&.text
                           end
                  o_text ||= iq.question.options[index].text
                  text "• #{full_sanitizer.sanitize(o_text)}:  #{res}" unless res.blank?
                else
                  o_text = if @survey.language == @instrument.language
                             iq.question.options[res.to_i].to_s
                           else
                             iq.question.options[res.to_i].translations.where(language: @survey.language)&.first&.text
                           end
                  o_text ||= iq.question.options[res.to_i].text
                  text html_decode("• #{full_sanitizer.sanitize(o_text)}")
                end
              end
            end
          end
        else
          text "• #{response&.text}" unless response&.text.blank?
        end
        text "• #{response&.special_response}" unless response&.special_response.blank?
      end
    end
    move_down 5
  end
end
