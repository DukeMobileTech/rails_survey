# frozen_string_literal: true

# == Schema Information
#
# Table name: projects
#
#  id                :integer          not null, primary key
#  name              :string
#  description       :text
#  created_at        :datetime
#  updated_at        :datetime
#  survey_aggregator :string
#

class Project < ActiveRecord::Base
  include SynchAble
  has_many :instruments, dependent: :destroy
  has_many :instrument_questions, through: :instruments
  has_many :questions, through: :instrument_questions
  has_many :next_questions, through: :instrument_questions
  has_many :multiple_skips, through: :instrument_questions
  has_many :condition_skips, through: :instrument_questions
  has_many :follow_up_questions, through: :instrument_questions
  has_many :options, through: :questions
  has_many :option_sets, through: :questions
  has_many :option_in_option_sets, through: :option_sets
  has_many :displays, through: :instruments
  has_many :surveys, through: :instruments
  has_many :project_devices, dependent: :destroy
  has_many :devices, through: :project_devices
  has_many :responses, through: :surveys
  has_many :response_images, through: :responses
  has_many :user_projects, dependent: :destroy
  has_many :users, through: :user_projects
  has_many :response_exports, through: :instruments
  has_many :response_images_exports, through: :response_exports
  has_many :images, through: :questions
  has_many :randomized_factors, through: :instruments
  has_many :randomized_options, through: :randomized_factors
  has_many :question_randomized_factors, through: :questions
  has_many :sections, through: :instruments
  has_many :project_device_users
  has_many :device_users, through: :project_device_users
  has_many :instrument_rules, through: :instruments
  has_many :grids, through: :instruments
  has_many :grid_labels, through: :grids
  has_many :metrics, through: :instruments
  has_many :rosters, dependent: :destroy
  has_many :score_schemes, through: :instruments
  has_many :score_units, through: :score_schemes
  has_many :option_scores, through: :score_units
  has_many :score_unit_questions, through: :score_units
  has_many :scores, through: :score_schemes
  has_many :critical_responses, through: :instruments
  validates :name, presence: true, allow_blank: false
  validates :description, presence: true, allow_blank: true

  def api_option_sets
    option_set_ids = api_questions.pluck(:option_set_id) + api_questions.pluck(:special_option_set_id)
    OptionSet.includes(:instruction).where(id: option_set_ids).uniq
  end

  def api_options
    Option.includes(:translations).where(id: api_option_in_option_sets.pluck(:option_id).uniq)
  end

  def api_instrument_questions
    InstrumentQuestion.includes(:instrument, :critical_responses, :all_loop_questions, question: %i[instruction option_set], translations: [:question]).where(instrument_id: published_instruments.pluck(:id))
  end

  def api_option_in_option_sets
    option_set_ids = api_option_sets.pluck(:id)
    OptionInOptionSet.where(option_set_id: option_set_ids)
  end

  def api_questions
    Question.where(id: api_instrument_questions.pluck(:question_id).uniq)
  end

  def api_displays
    Display.includes(:display_translations).where(instrument_id: published_instruments.pluck(:id))
  end

  def api_display_instructions
    DisplayInstruction.includes(:instrument_question).where(display_id: api_displays.pluck(:id))
  end

  def api_validations
    Validation.where(id: api_questions.pluck(:validation_id).uniq)
  end

  def api_instructions
    Instruction.includes(:instruction_translations).where(id: api_questions.pluck(:instruction_id) | api_display_instructions.pluck(:instruction_id) | critical_responses.with_deleted.pluck(:instruction_id))
  end

  def special_option_sets
    questions.uniq.collect(&:special_option_set).uniq.compact
  end

  def non_responsive_devices
    devices.includes(:surveys).where('surveys.updated_at < ?', Settings.danger_zone_days.days.ago).order('surveys.updated_at ASC')
  end

  def published_instruments
    instruments.where(published: true)
  end

  def self.all_published_instruments
    Instrument.where(published: true)
  end

  def instrument_response_exports
    ResponseExport.where(instrument_id: instrument_ids).order('created_at desc')
  end

  def daily_response_count
    count_per_day = {}
    array = []
    response_count_per_period(:group_responses_by_day).each do |day, count|
      count_per_day[day.to_s[5..9]] = count.inject { |sum, x| sum + x }
    end
    array << count_per_day
  end

  def hourly_response_count
    count_per_hour = {}
    array = []
    response_count_per_period(:group_responses_by_hour).each do |hour, count|
      count_per_hour[hour.to_s] = count.inject { |sum, x| sum + x }
    end
    array << sanitize(count_per_hour)
  end

  def device_surveys(device)
    surveys.where(device_uuid: device.identifier)
  end

  def aggregators
    if survey_aggregator == 'device_uuid'
      aggs = []
      uuids = surveys.pluck(:device_uuid).uniq
      uuids.each do |uuid|
        aggs << surveys.find_by_device_uuid(uuid)
      end
      aggs
    elsif survey_aggregator == 'Center ID'
      surveys.select(&:center_id).uniq
    elsif survey_aggregator == 'Participant ID'
      surveys.select(&:participant_id).uniq
    else
      surveys
    end
  end

  def aggregator_label(aggregator)
    if survey_aggregator == 'device_uuid'
      devices.where(identifier: aggregator.device_uuid).try(:first).try(:label)
    elsif survey_aggregator == 'Center ID'
      aggregator.center_id
    elsif survey_aggregator == 'Participant ID'
      aggregator.participant_id
    else
      aggregator.uuid
    end
  end

  def aggregator_survey_count(agg)
    surveys_by_aggregator(agg).size
  end

  def surveys_by_aggregator(agg)
    if survey_aggregator == 'device_uuid'
      surveys.where(device_uuid: agg.device_uuid)
    elsif survey_aggregator == 'Center ID'
      surveys.select { |s| s.center_id == agg.center_id }
    elsif survey_aggregator == 'Participant ID'
      surveys.select { |s| s.participant_id == agg.participant_id }
    else
      surveys
    end
  end

  def survey_aggregator
    read_attribute(:survey_aggregator).nil? ? 'device_uuid' : read_attribute(:survey_aggregator)
  end

  def to_csv
    CSV.generate do |csv|
      export(csv)
    end
  end

  def export(csv)
    published_instruments = instruments.includes(:instrument_questions).where(published: true)
    all_headers = Set['instrument_id', 'survey_id']
    published_instruments.each do |instrument|
      instrument_headers = instrument.short_headers
      instrument_headers.shift # Remove the first element
      instrument_headers.each_slice(2) do |qid| # Iterate over question IDs
        all_headers.merge([qid.first, qid.last, "#{qid.first}_text"])
      end
    end
    all_headers = all_headers.to_a
    headers = Hash[all_headers.map.with_index.to_a]
    csv << all_headers
    published_instruments.each do |instrument|
      instrument_headers = instrument.short_headers
      instrument_headers.shift
      instrument.surveys.includes(:survey_export).each do |survey|
        row = Array.new(all_headers.size)
        row[0] = instrument.id
        row[1] = survey.id
        unless survey.survey_export.short.nil?
          data = JSON.parse(survey.survey_export.short)
          data.shift
          survey_hash = Hash[instrument_headers.zip(data)]
          survey_hash.each do |question_identifier, response_text|
            qid_index = headers[question_identifier]
            row[qid_index] = response_text if qid_index
          end
          csv << row
        end
      end
    end
  end

  def self.generate_neighbor_data
    all_published_instruments.each do |instrument|
      instrument.instrument_questions.each do |iq|
        NeighborDataWorker.perform_async(iq.id)
      end
    end
  end

  def self.pofo_similar_questions
    sanitizer = Rails::Html::FullSanitizer.new
    # no-cutoff, 0.25-cutoff, 0.10-cutoff
    # cutoff_values = [2.0, 0.25, 0.10]
    header = ['question_number', 'question_sequence', 'instrument_title', 'section_title', 'display_title', 'question_identifier', 'neighbor_distance', 'neighbor_text_distance', 'neighbor_option_distance', 'question_text', 'sanitized_question_text']
    20.times do |i|
      header << "option_#{i}"
    end
    # generate csv for no-cutoff
    # no_cutoff_file = Tempfile.new(["POFO-similar-questions-by-combined-distance-no-cutoff", ".csv"])
    # cutoff_0_10_file = Tempfile.new(["POFO-similar-questions-by-combined-distance-cutoff-0.10", ".csv"])
    # cutoff_0_25_file = Tempfile.new(["POFO-similar-questions-by-combined-distance-cutoff-0.25", ".csv"])
    cutoff_0_10_file = Tempfile.new(["POFO-similar-questions-by-text-distance-cutoff-0.10", ".csv"])
    cutoff_0_25_file = Tempfile.new(["POFO-similar-questions-by-text-distance-cutoff-0.25", ".csv"])

    list_0_10 = []
    list_0_25 = []
    # list_no_cutoff = []

    # cutoff_0_25_file.write(CSV.generate do |csv|
      # csv << header
      all_published_instruments.order(:id).each do |instrument|
        instrument.instrument_questions.order(:number_in_instrument).each do |iq|
          prefix = iq.instrument.project.name == 'POFO III' ? "p3#" : ""
          row = [iq.number_in_instrument, '', instrument.title, iq.section_title, iq.display_title, "#{prefix}#{iq.identifier}", '', '', '', sanitizer.sanitize(iq.question.text).to_s.strip, iq.sanitized_question_text]
          iq.non_special_options.each do |opt|
            row << sanitizer.sanitize(opt.text).to_s.strip
          end
          # csv << row
          list_0_10 << row
          list_0_25 << row
          # list_no_cutoff << row
          combined_hash = JSON.parse(iq.neighbors_by_combined_distance || '{}')
          text_hash = JSON.parse(iq.neighbors_by_text_distance || '{}')
          rows = []
          # combined_hash.each do |instrument_id, iq_neighbor_data|
          text_hash.each do |instrument_id, iq_neighbor_data|
            new_instrument = Instrument.find_by(id: instrument_id.to_i)
            iq_neighbor_hash = JSON.parse(iq_neighbor_data || '{}')
            sequence = 1
            iq_neighbor_hash.each do |neighbor_iq_id, neighbor_data|
              distances = neighbor_data.split(',')
              next if distances[0].to_f > 0.25

              neighbor = new_instrument.instrument_questions.find_by(id: neighbor_iq_id.to_i)
              prefix = neighbor.instrument.project.name == 'POFO III' ? "p3#" : ""
              row = ['', sequence, new_instrument.title, neighbor.section_title, neighbor.display_title, "#{prefix}#{neighbor.identifier}", distances[0], distances[1], distances[2], sanitizer.sanitize(neighbor.question.text).to_s.strip, neighbor.sanitized_question_text]
              neighbor.non_special_options.each do |opt|
                row << sanitizer.sanitize(opt.text).to_s.strip
              end
              rows << row
              sequence += 1
            end
          end
          # sort rows by neighbor_distance (6th column or 7th column) from smallest to largest
          # rows.sort_by! { |r| r[6] || Float::INFINITY }
          rows.sort_by! { |r| r[7] || Float::INFINITY }
          rows.each do |r|
            # csv << r
            # list_no_cutoff << r
            # if r[6].to_f <= 0.25
            if r[7].to_f <= 0.25
              list_0_25 << r
            end
            # if r[6].to_f <= 0.10
            if r[7].to_f <= 0.10
              list_0_10 << r
            end
          end
          # csv << [] # Blank line between different questions
          # list_no_cutoff << []
          list_0_25 << []
          list_0_10 << []
        end
        # break # test first instrument only; TODO: remove this break to generate for all instruments (warning: will take a long time and generate a very large file)
      end
    # end)

    # write to files
    # no_cutoff_file.write(CSV.generate do |csv|
    #   csv << header
    #   list_no_cutoff.each do |r|
    #     csv << r
    #   end
    # end)
    cutoff_0_10_file.write(CSV.generate do |csv|
      csv << header
      list_0_10.each do |r|
        csv << r
      end
    end)
    cutoff_0_25_file.write(CSV.generate do |csv|
      csv << header
      list_0_25.each do |r|
        csv << r
      end
    end)

    # create a zip file and add the csv file to it
    zip_file = Tempfile.new(["POFO-similar-questions", ".zip"])
    Zip::File.open(zip_file.path, Zip::File::CREATE) do |zip|
      # zip.add("pofo2-pofo3-similar-questions-by-combined-distance-no-cutoff.csv", no_cutoff_file.path)
      # zip.add("pofo2-pofo3-similar-questions-by-combined-distance-cutoff-0.10.csv", cutoff_0_10_file.path)
      # zip.add("pofo2-pofo3-similar-questions-by-combined-distance-cutoff-0.25.csv", cutoff_0_25_file.path)
      zip.add("pofo2-pofo3-similar-questions-by-text-distance-cutoff-0.10.csv", cutoff_0_10_file.path)
      zip.add("pofo2-pofo3-similar-questions-by-text-distance-cutoff-0.25.csv", cutoff_0_25_file.path)
    end
    # send the zip file to download method
    zip_file
  end

  def neighboring_questions_to_csv
    sort_position = 7 # 6 = combined, 7 = text
    decimal_limit = 0.00001
    distance_cutoff = 0.10 # 0.10, 0.25, 2.0
    similar_limit = 5
    sanitizer = Rails::Html::FullSanitizer.new
    header = ['question_number', 'question_sequence', 'instrument_title', 'section_title', 'display_title', 'question_identifier', 'neighbor_distance', 'neighbor_text_distance', 'neighbor_option_distance', 'question_text', 'sanitized_question_text']
    20.times do |i|
      header << "option_#{i}"
    end

    CSV.generate do |csv|
      csv << header
      published_instruments.order(:id).each do |instrument|
        instrument.instrument_questions.includes(question: :options).order(:number_in_instrument).each do |iq|
          text = sanitizer.sanitize(iq.question.text).to_s.strip
          row = [iq.number_in_instrument, '', instrument.title, iq.section_title, iq.display_title, "q$#{iq.identifier}", "", "", "", text, iq.sanitized_question_text]
          iq.question.options.each do |opt|
            row << sanitizer.sanitize(opt.text).to_s.strip
          end
          csv << row
          neighbor_rows = []
          other_instruments = published_instruments.where.not(id: instrument.id).order(:id)
          other_instruments.each do |other_instrument|
            # neighbors = iq.most_similar_in_instrument(other_instrument, limit: similar_limit, distance: 'cosine')
            neighbors = iq.most_similar_in_instrument_text(other_instrument, limit: similar_limit, distance: 'cosine')
            next if neighbors.blank?
            neighbors.each_with_index do |neighbor, index|
              if neighbor && neighbor.neighbor_distance <= distance_cutoff
                neighbor_text = sanitizer.sanitize(neighbor.question.text).to_s.strip
                # distance1 = neighbor.neighbor_distance
                distance1 = iq.neighbor_combined_distance(neighbor)
                distance1 = (distance1.abs < decimal_limit ? 0.0 : distance1.round(5)) if distance1
                # distance2 = iq.neighbor_text_distance(neighbor)
                distance2 = neighbor.neighbor_distance
                distance2 = (distance2.abs < decimal_limit ? 0.0 : distance2.round(5)) if distance2
                distance3 = iq.neighbor_option_distance(neighbor)
                distance3 = (distance3.abs < decimal_limit ? 0.0 : distance3.round(5)) if distance3
                row = ['', index + 1, other_instrument.title, neighbor.section_title, neighbor.display_title, "q$#{neighbor.identifier}", distance1, distance2, distance3, neighbor_text, neighbor.sanitized_question_text]
                neighbor.question.options.each do |opt|
                  row << sanitizer.sanitize(opt.text).to_s.strip
                end
                neighbor_rows << row
              end
            end
          end
          # sort neighbor_rows by neighbor_distance (7th/8th column) from smallest to largest
          neighbor_rows.sort_by! { |r| r[sort_position] || Float::INFINITY }
          neighbor_rows.each do |nrow|
            csv << nrow
          end
          csv << [] # Blank line between different questions
        end
      end
    end
  end

  def similar_questions_to_csv
    sanitizer = Rails::Html::FullSanitizer.new
    # Use the project's published instruments and eager load questions + options
    instrument_list = published_instruments.includes(instrument_questions: { question: :options }).to_a

    header = ['question_text', 'question_options'] + instrument_list.map(&:title)

    # grouped[[text, options_text]] => array per-instrument of identifier arrays
    grouped = Hash.new { |h, k| h[k] = Array.new(instrument_list.size) { [] } }

    instrument_list.each_with_index do |inst, idx|
      inst.instrument_questions.each do |iq|
        q = iq.question
        text = sanitizer.sanitize(q.text).to_s.strip
        options_text = q.options.map { |opt| sanitizer.sanitize(opt.text).to_s.strip }.join('$')
        key = [text, options_text]
        grouped[key][idx] << "q$#{iq.identifier}"
      end
    end

    CSV.generate do |csv|
      csv << header

      # Preserve insertion order (first-seen grouping). Change to sort if desired.
      grouped.each do |(text, options_text), per_instrument_arrays|
        # Primary row: question text + identifiers per instrument
        question_row = [text, '']
        instrument_cells = per_instrument_arrays.map { |arr| arr.empty? ? '' : arr.join('; ') }
        question_row.concat(instrument_cells)
        csv << question_row

        # Subsequent rows: one row per option; no identifiers repeated on option rows
        next if options_text.to_s.strip.empty?

        options = options_text.split('$')
        options.each_with_index do |opt_text, opt_idx|
          opt = opt_text.to_s.strip
          next if opt.empty?
          option_row = ['', opt]
          # For each instrument, if it has one or more instrument_question identifiers,
          # append q$<identifier>$<option_index> (join multiple with '; ')
          instrument_cells = per_instrument_arrays.map do |id_arr|
            if id_arr.empty?
              ''
            else
              id_arr.map { |iid| "#{iid}$#{opt_idx}" }.join('; ')
            end
          end
          option_row.concat(instrument_cells)
          csv << option_row
        end
      end
    end
  end

  def questions_to_csv
    CSV.generate do |csv|
      header, row = instrument_export
      csv << header
      csv << row
    end
  end

  def instrument_export
    sanitizer = Rails::Html::FullSanitizer.new
    option_headers = {}
    option_data = {}
    iq_data = {}
    published_instruments = instruments.includes(instrument_questions: { loop_questions: {}, question: :options }).where(published: true)
    published_instruments.each do |instrument|
      instrument.instrument_questions.each do |iq|
        next if iq_data.key?("q_#{iq.identifier}")

        if iq.loop_questions.exists?
          handle_loop_question(instrument, iq, option_headers, option_data, iq_data, sanitizer)
        end

        q_option_headers = []
        q_option_data = []
        iq.question.options.each_with_index do |option, index|
          q_option_headers << "q_#{iq.identifier}_#{index}"
          q_option_data << sanitizer.sanitize(option.text)
        end
        option_headers["q_#{iq.identifier}"] = q_option_headers
        option_data["q_#{iq.identifier}"] = q_option_data
        iq_data["q_#{iq.identifier}"] = sanitizer.sanitize(iq.question.text)
      end
    end
    header = []
    row = []
    iq_data.each do |identifier, question_text|
      header << identifier
      row << question_text
      header += option_headers[identifier]
      row += option_data[identifier]
    end
    [header, row]
  end

  def handle_loop_question(instrument, iq, option_headers, option_data, iq_data, sanitizer)
    iq.loop_questions.each do |lq|
      parent = instrument.instrument_question_by_identifier(lq.parent)
      looped = instrument.instrument_question_by_identifier(lq.looped)
      if iq.question.question_type == 'INTEGER'
        (1..12).each do |n|
          identifier = "q_#{lq.parent}_#{lq.looped}_#{n}"
          if !iq_data.key?(identifier)
            iq_data[identifier] = sanitizer.sanitize("#{parent.question.text} : #{looped.question.text} : #{n}")
            handle_looped_question_options(looped, identifier, option_headers, option_data, sanitizer)
          end
        end
      elsif !lq.option_indices.blank?
        lq.option_indices.split(',').each do |ind|
          identifier = "q_#{lq.parent}_#{lq.looped}_#{ind}"
          if !iq_data.key?(identifier)
            option = parent.question.options[ind.to_i]
            iq_data[identifier] = sanitizer.sanitize("#{parent.question.text} : #{looped.question.text} : #{option.text}")
            handle_looped_question_options(looped, identifier, option_headers, option_data, sanitizer)
          end
        end
      else
        iq.question.options.each_with_index do |_option, idx|
          identifier = "q_#{lq.parent}_#{lq.looped}_#{idx}"
          if !iq_data.key?(identifier)
            option = parent.question.options[idx]
            iq_data[identifier] = sanitizer.sanitize("#{parent.question.text} : #{looped.question.text} : #{option.text}")
            handle_looped_question_options(looped, identifier, option_headers, option_data, sanitizer)
          end
        end
      end
    end
  end

  def handle_looped_question_options(looped, identifier, option_headers, option_data, sanitizer)
    q_option_headers = []
    q_option_data = []
    looped.question.options.each_with_index do |option, index|
      q_option_headers << "#{identifier}_#{index}"
      q_option_data << sanitizer.sanitize(option.text)
    end
    option_headers[identifier] = q_option_headers
    option_data[identifier] = q_option_data
  end

  private

  def sanitize(hash)
    (0..23).each do |h|
      hour = format '%02d', h
      hash[hour] = 0 unless hash.key?(hour)
    end
    hash
  end

  def response_count_per_period(method)
    grouped_responses = []
    instruments.each do |instrument|
      instrument.surveys.each do |survey|
        grouped_responses << survey.send(method)
      end
    end
    merge_period_counts(grouped_responses)
  end

  def merge_period_counts(grouped_responses)
    grouped_responses.map(&:to_a).flatten(1).each_with_object({}) { |(k, v), h| (h[k] ||= []) << v; }
  end
end
