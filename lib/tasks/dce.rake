# frozen_string_literal: true

# Run using the command rake 'dce[:project_id]'
desc 'Create DCE tasks from CSV files'
task :dce, [:project_id] => :environment do |_t, args|
  project = Project.find_by(id: args[:project_id].to_i)
  if project.nil?
    Rake::Task['setup'].reenable
    Rake::Task['setup'].invoke
    project = Project.first
  end
  instrument = project.instruments.create_with(published: true, language: 'en')
                      .find_or_create_by(title: 'DCE Choice Tasks')
  language = 'sw'
  instrument.translations.create_with(title: 'DCE Kazi Za Kuchagua', active: true)
            .find_or_create_by(language: language)
  puts instrument.inspect
  files = ["#{Rails.root}/files/dce/DCEMergeMen.csv",
           "#{Rails.root}/files/dce/DCEMergeWomen.csv"]
  files.each do |filename|
    puts "name = #{filename}"
    CSV.foreach(filename, headers: true) do |row|
      break if row[0].blank?

      question_set = QuestionSet.find_or_create_by(title: filename.split('/').last.split('.').first)
      puts question_set.inspect
      instrument.reload
      section = instrument.sections.create_with(position: instrument.sections.size + 1)
                          .find_or_create_by(title: row[4])
      puts section.inspect
      question_set.reload
      folder = question_set.folders.create_with(position: question_set.folders.size)
                           .find_or_create_by(title: row[4])
      puts folder.inspect
      section.reload
      instrument.reload
      display = section.displays.create_with(instrument_id: instrument.id,
                                             position: section.displays.size + 1,
                                             instrument_position: instrument.displays.size + 1)
                       .find_or_create_by(title: "#{row[4]}-#{row[6]}")
      puts display.inspect
      first_text = 'If these options were available to you right now, which option would you prefer: A, B or C?'
      first_text_sw = 'Kama chaguo hizi zingepatikana kwako sasa, bila gharama, ni chaguo gani ungependelea: A, B au C?'
      second_text = 'Of the two remaining options, which option would you prefer?'
      second_text_sw = 'Kwa chaguo mbili zilizobaki, ni gani ungependelea?'
      ins_one = Instruction.create_with(text: first_text).find_or_create_by(title: first_text)
      ins_one.instruction_translations.create_with(text: first_text_sw)
             .find_or_create_by(language: language)
      ins_two = Instruction.create_with(text: second_text).find_or_create_by(title: second_text)
      ins_two.instruction_translations.create_with(text: second_text_sw)
             .find_or_create_by(language: language)
      folder.reload
      question = folder.questions.create_with(text: 'Please consider the following three options.',
                                              question_type: 'CHOICE_TASK',
                                              question_set_id: folder.question_set_id,
                                              after_text_instruction_id: ins_one.id,
                                              position: folder.questions.size + 1)
                       .find_or_create_by(question_identifier: "#{row[3]}-#{row[4]}")
      question.translations.create_with(text: 'Tafadhali zingatia chaguo tatu zifuatazo.')
              .find_or_create_by(language: language)

      option_set = OptionSet.create_with(instruction_id: ins_two.id)
                            .find_or_create_by(title: "#{row[3]}-#{row[4]}")
      question.option_set_id = option_set.id
      question.save
      display.reload
      instrument.reload
      iq = display.instrument_questions.create_with(instrument_id: instrument.id,
                                                    question_id: question.id,
                                                    position: display.instrument_questions.size + 1,
                                                    number_in_instrument: instrument.instrument_questions.size + 1)
                  .find_or_create_by(identifier: "#{row[3]}-#{row[4]}")

      %w[A B C].each do |letter|
        Option.find_or_create_by(identifier: "#{row[3]}-#{row[4]}-#{letter}") do |option|
          option.text = "Option #{letter}"
          option.save
          option.translations.create_with(text: "Chaguo #{letter}")
                .find_or_create_by(language: language)
          option_set.reload
          option_set.option_in_option_sets.find_or_create_by(option_id: option.id) do |oios|
            oios.number_in_question = option_set.option_in_option_sets.size + 1
            oios.save
            cells = { 'A' => [8, 9, 10, 11, 12, 13],
                      'B' => [14, 15, 16, 17, 18, 19],
                      'C' => [20, 21, 22, 23, 24, 25] }
            index = 0
            cells[letter].each_slice(2) do |t_cell, i_cell|
              collage = Collage.find_or_create_by(name: "#{row[t_cell]}-#{row[i_cell]}")
              oios.option_collages.create_with(position: index).find_or_create_by(collage_id: collage.id)
              t_option = Option.create_with(text: row[t_cell]).find_or_create_by(identifier: row[t_cell])
              collage.diagrams.create_with(position: 0).find_or_create_by(option_id: t_option.id)
              i_option = Option.create_with(text: row[i_cell]).find_or_create_by(identifier: row[i_cell])
              collage.diagrams.create_with(position: 1).find_or_create_by(option_id: i_option.id)
              index += 1
            end
          end
        end
      end
      section.reload
      instrument.reload
      fol_dis = section.displays.create_with(instrument_id: instrument.id,
                                             position: section.displays.size + 1,
                                             instrument_position: instrument.displays.size + 1)
                       .find_or_create_by(title: "#{row[4]}-#{row[6]}-Followup")
      puts fol_dis.inspect
      txt = 'If you could start using this option today, right now, or continue to do what you normally do, what would you prefer?'
      txt_sw = 'Kama ungeweza kuanza kutumia chaguo hili leo, sasa hivi, ama kuendelea kufanya kile unachofanya kwa kawaida, ungependelea kipi?'
      instruction = Instruction.create_with(text: txt).find_or_create_by(title: txt)
      instruction.instruction_translations.create_with(text: txt_sw)
                 .find_or_create_by(language: language)
      os = OptionSet.find_or_create_by(title: 'Best Option Preference')
      sw_translations = ['Anza kutumia chaguo hili leo',
                         'Endelea kufanya kile unacho kifanya kwa kawaida',
                         'Sina uhakika']
      ['Start using this option today',
       'Continue to do what you normally do',
       'Not sure'].each_with_index do |text, index|
        opt = Option.create_with(text: text).find_or_create_by(identifier: text)
        opt.translations.create_with(text: sw_translations[index])
           .find_or_create_by(language: language)
        os.option_in_option_sets
          .create_with(number_in_question: index + 1)
          .find_or_create_by(option_id: opt.id)
      end

      folder.reload
      fol_qst = folder.questions.create_with(text: '<p>You selected [followup] as your most preferred option.</p>',
                                             question_type: 'SELECT_ONE',
                                             option_set_id: os.id,
                                             question_set_id: folder.question_set_id,
                                             after_text_instruction_id: instruction.id,
                                             position: folder.questions.size + 1)
                      .find_or_create_by(question_identifier: "#{row[3]}-#{row[4]}-Followup")
      fol_qst.translations.create_with(text: '<p>Ulichagua [followup] kama chaguo unalopendelea zaidi.</p>')
             .find_or_create_by(language: language)

      fol_dis.reload
      instrument.reload
      fol_dis.instrument_questions.create_with(instrument_id: instrument.id,
                                               question_id: fol_qst.id,
                                               position: fol_dis.instrument_questions.size + 1,
                                               number_in_instrument: instrument.instrument_questions.size + 1,
                                               carry_forward_identifier: iq.identifier)
             .find_or_create_by(identifier: "#{row[3]}-#{row[4]}-Followup")
    end
  end
end