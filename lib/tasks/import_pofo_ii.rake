
desc "Import Pofo II data from CSV file"
task import_pofo_ii: :environment do
  filename = Rails.root.join('lib', 'data', 'pofo_ii.csv')

  unless File.exist?(filename)
    puts "Error: #{filename} not found"
    return
  end

  # Ensure the project exists
  project = Project.where(name: 'POFO II').first
  unless project
    project = Project.create!(name: 'POFO II', description: 'Project for POFO II data')
  end

  CSV.foreach(filename, headers: true) do |row|
    next if row['instrument_name'].blank?

    instrument = project.instruments.where(title: row['instrument_name'].strip).first
    instrument ||= project.instruments.create!(title: row['instrument_name'].strip, language: 'en', alignment: 'left')
    question_set = QuestionSet.where(title: row['instrument_name'].strip).first
    question_set ||= QuestionSet.create!(title: row['instrument_name'].strip)
    folder = question_set.folders.where(title: row['instrument_name'].strip).first
    folder ||= question_set.folders.create!(title: row['instrument_name'].strip)
    section = instrument.sections.where(title: row['instrument_name'].strip).first
    section ||= instrument.sections.create!(title: row['instrument_name'].strip)
    display = section.displays.where(title: row['instrument_name'].strip).first
    display ||= section.displays.create!(title: row['instrument_name'].strip, instrument: instrument, position: instrument.displays.size + 1, mode: 'MULTIPLE')

    question = Question.where(question_identifier: "p2##{row['question_identifier'].strip}").first
    unless question
      option_set = OptionSet.where(title: row['response_options'].strip).first if row['response_options'].present?
      if option_set.nil? && row['response_options'].present?
        option_set = OptionSet.create!(title: row['response_options'].strip)
        response_options = row['response_options'].to_s.split(' $ ').map(&:strip)
        response_options.each_with_index do |option_text, index|
          option = Option.where(identifier: option_text).first
          option ||= Option.create!(text: option_text, identifier: option_text)
          OptionInOptionSet.create!(
            option_set: option_set,
            option: option,
            number_in_question: index + 1
          )
        end
      end
      question = Question.new(
        question_identifier: "p2##{row['question_identifier'].strip}",
        text: row['question_text'].strip,
        question_type: response_options.present? ? 'SELECT_ONE' : 'FREE_RESPONSE',
        question_set: question_set,
        folder: folder,
        option_set: option_set
      )
      question.save!
    end
    instrument_question = instrument.instrument_questions.where(identifier: "p2##{row['question_identifier'].strip}").first
    unless instrument_question
      instrument_question = instrument.instrument_questions.new(
        question: question,
        display: display,
        number_in_instrument: instrument.instrument_questions.size + 1,
        identifier: "p2##{row['question_identifier'].strip}"
      )
      instrument_question.save!
    end
  end
  puts "Pofo II data import completed."
end
