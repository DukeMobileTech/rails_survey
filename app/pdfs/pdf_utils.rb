# frozen_string_literal: false

module PdfUtils
  QUESTION_LEFT_MARGIN = 40
  QUESTION_NUMBER_MARGIN = 5
  AFTER_INSTRUCTIONS_MARGIN = 5
  QUESTION_TEXT_MARGIN = 5
  CHOICE_TEXT_MARGIN = 2
  AFTER_OPTIONS_MARGIN = 5
  MINIMUM_REMAINING_HEIGHT = 75
  OPTION_LEFT_MARGIN = 5
  CIRCLE_SIZE = 5
  SQUARE_SIZE = 10
  AFTER_OTHER_LINE_MARGIN = 15
  AFTER_TITLE_MARGIN = 15
  AFTER_HORIZONTAL_RULE_MARGIN = 10
  AFTER_QUESTION_MARGIN = 20
  NUMBER_OF_COLUMNS = 2
  FONT_SIZE = 10
  PAGE = '<page>'.freeze
  LETTERS = ('a'..'z').to_a

  def register_fonts
    font_families.update(
      'Noto Sans' => {
        normal: "#{Rails.root}/app/pdfs/fonts/NotoSans-Regular.ttf",
        bold: "#{Rails.root}/app/pdfs/fonts/NotoSans-Bold.ttf",
        italic: "#{Rails.root}/app/pdfs/fonts/NotoSans-Italic.ttf"
      },
      'KhmerOS' => {
        normal: "#{Rails.root}/app/pdfs/fonts/KhmerOS.ttf"
      },
      'Noto Sans Ethiopic' => {
        normal: "#{Rails.root}/app/pdfs/fonts/NotoSansEthiopic-Regular.ttf"
      }
    )
    font 'Noto Sans'
    font_size FONT_SIZE
    self.fallback_fonts = ['KhmerOS', 'Noto Sans Ethiopic']
  end

  def format_special_responses(question)
    return unless question.special_options

    indent(QUESTION_LEFT_MARGIN) do
      text "Or: #{question.special_options.join(' / ')}"
    end
  end

  def format_question_number(question)
    text "#{question.number_in_instrument})", size: FONT_SIZE + 6, style: :bold
    text question.identifier, size: FONT_SIZE - 2, style: :bold
  end

  def format_instructions(instructions)
    text sanitize_text(instructions), inline_format: true
    move_down AFTER_INSTRUCTIONS_MARGIN unless instructions.blank?
  end

  def format_question_text(question_text)
    text sanitize_text(question_text), inline_format: true
    move_down QUESTION_TEXT_MARGIN
  end

  def format_display_text(text)
    text "<u>#{text}</u>", align: :center, size: FONT_SIZE + 3, inline_format: true
  end

  def format_section_text(text)
    text "<u>#{remove_tags(text)}</u>", align: :center, size: FONT_SIZE + 5, style: :bold, inline_format: true
  end

  def remove_tags(text)
    text = text.gsub('<p>', '')
    text.gsub('</p>', '')
  end

  def sanitize_text(text)
    return text if text.nil?

    sanitizer = Rails::Html::WhiteListSanitizer.new
    tags = %w[b i u strikethrough sub sup]
    text = text.delete("\n")
    text = text.gsub('</p>', "\n")
    text = text.gsub('</div>', "\n")
    text = text.gsub('<br>', "\n")
    sanitizer.sanitize(text, tags: tags)
  end

  def format_choice_instructions(str)
    indent(QUESTION_LEFT_MARGIN) do
      pad(2) { text sanitize_text(str), inline_format: true }
    end
    move_down CHOICE_TEXT_MARGIN
  end

  def format_question_choices(question, language = nil)
    indent(QUESTION_LEFT_MARGIN) do
      if question.non_special_options? && !question.slider_variant?
        question.non_special_options.each_with_index do |option, index|
          draw_choice(option, index, question, language)
        end
      elsif question.slider_variant?
        draw_slider(question, language)
      end
      draw_other(question) if question.other?
    end
    move_down AFTER_OPTIONS_MARGIN
  end

  def question_associations(question)
    [question.next_questions, question.multiple_skips, question.loop_questions,
     question.critical_responses, question.non_special_options]
  end

  def options_to_h(options)
    hash = {}
    options.each do |option|
      hash[option.identifier] = option
    end
    hash
  end

  def format_skip_patterns(question)
    next_questions, multiple_skips, loop_questions, critical_responses, options = question_associations(question)
    instrument_questions = question.instrument.instrument_questions
    options_hash = options_to_h(options)
    indent(QUESTION_LEFT_MARGIN) do
      unless next_questions.blank?
        next_questions.each do |next_question|
          option = options_hash[next_question.option_identifier]
          skip_to_question = instrument_questions.where(identifier: next_question.next_question_identifier).first
          if option
            index = options.index(option)
            skip_string = "=> If <b>(#{LETTERS[index]})</b> skip to <b>##{skip_to_question.number_in_instrument}</b> (#{next_question.next_question_identifier})"
          else
            skip_string = "=> If <b>#{next_question.option_identifier}</b> skip to <b>##{skip_to_question.number_in_instrument}</b> (#{next_question.next_question_identifier})"
          end
          text skip_string, inline_format: true, size: FONT_SIZE - 2
        end
      end
      unless multiple_skips.blank?
        multiple_skip_hash = multiple_skips.group_by(&:option_identifier)
        multiple_skip_hash.each do |option_identifier, m_skips|
          option = options_hash[option_identifier]
          skipped = ''
          m_skips.each do |m_skip|
            q = instrument_questions.where(identifier: m_skip.skip_question_identifier).first
            skipped << "<b>##{q.number_in_instrument}</b>, "
          end
          skip_string = if option
                          "* If <b>(#{LETTERS[options.index(option)]})</b> skip questions: #{skipped.strip.chop}"
                        else
                          "* If <b>#{option_identifier}</b> skip questions: #{skipped.strip.chop}"
                        end
          text skip_string, inline_format: true, size: FONT_SIZE - 2
        end
      end
      unless loop_questions.blank?
        skipped = ''
        loop_questions.each do |loop_question|
          q = instrument_questions.where(identifier: loop_question.looped).first
          skipped << "<b>##{q.number_in_instrument}</b>, "
        end
        skip_string = "-> Ask questions #{skipped.strip.chop} for each of the responses"
        text skip_string, inline_format: true, size: FONT_SIZE - 2
      end
      unless critical_responses.blank?
        critical_responses.each do |critical_response|
          option = options_hash[critical_response.option_identifier]
          instruction = Instruction.find(critical_response.instruction_id)
          if option
            index = options.index(option)
            caution = "<b>!! If (#{LETTERS[index]}): #{sanitize_text(instruction.text)}</b>"
          else
            caution = "<b>!! If #{critical_response.option_identifier}: #{sanitize_text(instruction.text)}</b>"
          end
          text caution, inline_format: true, color: 'FF0000', size: FONT_SIZE - 2
        end
      end
    end
  end

  def draw_choice(choice, index, question, language)
    bounds.move_past_bottom if y < MINIMUM_REMAINING_HEIGHT
    choice_text = choice.text
    translation = choice.translation_for(language) if language
    choice_text = translation.text if language && translation
    if question.list_of_boxes_variant?
      pad(2) { text "#{LETTERS[index]}) #{choice_text}" }
      pad(10) { stroke_horizontal_rule }
    else
      stroke_circle [bounds.left + OPTION_LEFT_MARGIN, cursor - 5], CIRCLE_SIZE if question.select_one_variant?
      stroke_rectangle [bounds.left + OPTION_LEFT_MARGIN, cursor - 5], SQUARE_SIZE, SQUARE_SIZE if question.select_multiple_variant?
      draw_bounding_box("#{LETTERS[index]}) ", choice_text, question)
    end
  end

  def draw_bounding_box(index, text_string, question)
    box_bounds = [bounds.left + OPTION_LEFT_MARGIN + 10, cursor + 5]
    box_bounds = [bounds.left + OPTION_LEFT_MARGIN + 20, cursor] if question.select_multiple_variant?
    bounding_box(box_bounds, width: bounds.width - (OPTION_LEFT_MARGIN * 2) - 10) do
      pad(2) { text "#{index}#{text_string}" }
    end
    move_down 2
  end

  def draw_other(question)
    left_pos = bounds.left + OPTION_LEFT_MARGIN
    right_pos = bounds.right - OPTION_LEFT_MARGIN - 10
    index = question.non_special_options.size
    if question.question_type == 'SELECT_ONE_WRITE_OTHER'
      stroke_circle [left_pos, cursor - 5], CIRCLE_SIZE
      draw_text "#{LETTERS[index]}) Other", at: [left_pos + CIRCLE_SIZE + OPTION_LEFT_MARGIN, cursor - 10]
      move_down 2
      horizontal_line left_pos + 20, right_pos, at: cursor - 10
    elsif question.question_type == 'SELECT_MULTIPLE_WRITE_OTHER'
      stroke_rectangle [left_pos, cursor - 5], SQUARE_SIZE, SQUARE_SIZE
      draw_text "#{LETTERS[index]}) Other", at: [left_pos + SQUARE_SIZE + OPTION_LEFT_MARGIN, cursor - 10]
      move_down 2
      horizontal_line left_pos + 30, right_pos, at: cursor - 15
    end
    move_down AFTER_OTHER_LINE_MARGIN
  end

  def draw_slider(question, language)
    left_pos = bounds.left + OPTION_LEFT_MARGIN
    right_pos = bounds.right - OPTION_LEFT_MARGIN
    step = (right_pos - left_pos) / 10
    horizontal_line left_pos, right_pos, at: cursor - 10
    0.upto(9) do |n|
      draw_text (n + 1).to_s, at: [left_pos + (n * step), cursor - 5]
    end
    return unless question.question_type == 'LABELED_SLIDER'

    move_down 10
    cursor_pos = cursor - 5
    width = (right_pos - left_pos) / question.non_special_options.count
    question.non_special_options.each_with_index do |option, index|
      bounding_box([left_pos + (width * index), cursor_pos], width: width) do
        if language
          text option.translated_for(language, :text)
        else
          text option.text
        end
      end
    end
  end

  def pad_after_question(question)
    return if Settings.question_with_options.include?(question.question_type)

    if question.question_type == 'FREE_RESPONSE'
      move_down 200
    else
      move_down 50
    end
  end

  def number_odd_pages
    odd_options = {
      at: [bounds.right - 150, 0],
      width: 150,
      align: :right,
      page_filter: :odd,
      start_count_at: 1
    }
    number_pages PAGE, odd_options
  end

  def number_even_pages
    even_options = {
      at: [0, bounds.left],
      width: 150,
      align: :left,
      page_filter: :even,
      start_count_at: 2
    }
    number_pages PAGE, even_options
  end
end
