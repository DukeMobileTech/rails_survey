# frozen_string_literal: true

# == Schema Information
#
# Table name: instrument_questions
#
#  id                   :integer          not null, primary key
#  question_id          :integer
#  instrument_id        :integer
#  number_in_instrument :integer
#  display_id           :integer
#  created_at           :datetime
#  updated_at           :datetime
#  identifier           :string
#  deleted_at           :datetime
#  table_identifier     :string
#  loop_questions_count :integer          default(0)
#  embedding            :vector(1536)
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

  has_neighbors :embedding
  has_neighbors :embedding_qtext
  has_neighbors :embedding_otext

  acts_as_paranoid
  has_paper_trail
  acts_as_taggable
  acts_as_taggable_on :countries

  validates :identifier, presence: true, uniqueness: { scope: :instrument_id, message: 'instrument already has this identifier' }

  after_update :update_display_instructions, if: :number_in_instrument_changed?
  after_destroy :renumber_questions

  def generate_embedding
    sanitized_qtext = sanitized_question_text
    sanitizer = Rails::Html::FullSanitizer.new
    options_text = question.options.map { |opt| sanitizer.sanitize(opt.text.to_s).squish }.join(' $ ') if question.options.present?
    prompt = "Question Text: #{sanitized_qtext}"
    prompt += "\nOptions Text: #{options_text}" if options_text.present?

    self.embedding = open_ai_embedding(prompt)
    if options_text.blank?
      self.embedding_otext = nil
      self.embedding_qtext = self.embedding
    else
      self.embedding_qtext = open_ai_embedding("Question Text: #{sanitized_qtext}")
      self.embedding_otext = open_ai_embedding("Options Text: #{options_text}")
    end
    save!
  end

  def open_ai_embedding(prompt)
    api_key = ENV['OPEN_AI_API_KEY']
    raise 'OpenAI API key not set (OPEN_AI_API_KEY)' unless api_key.present?

    client = OpenAI::Client.new(access_token: api_key)

    resp = client.embeddings(parameters: { model: 'text-embedding-3-small', input: prompt })
    vector = resp.dig('data', 0, 'embedding') || resp.dig(:data, 0, :embedding)
    unless vector && vector.is_a?(Array)
      Rails.logger.error "generate_embedding: no vector returned: #{resp.inspect}"
      return nil
    end

    expected = self.class.columns_hash['embedding']&.limit
    if expected && vector.length != expected
      Rails.logger.error "generate_embedding: embedding length #{vector.length} != expected #{expected}"
      raise "embedding length mismatch: got #{vector.length}, expected #{expected}"
    end

    vector
  rescue => e
    bt = Array(e.backtrace).join("\n")
    Rails.logger.error("generate_embedding failed for InstrumentQuestion id=#{id}: #{e.class}: #{e.message}\n#{bt}")
    errors.add(:base, "Embedding generation failed: #{e.message}")
    false
  end

  def country_specific(language, code)
    return false if language == 'en' || country_list.blank?

    return !country_list.include?('cambodia') if language == 'km'
    return !country_list.include?('ethiopia') if language == 'am'

    if language == 'sw'
      if code == 'ke'
        !country_list.include?('kenya')
      elsif code == 'tz'
        !country_list.include?('tanzania')
      else
        !country_list.include?('kenya') && !country_list.include?('tanzania')
      end
    end
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

  def sanitized_question_text
    sanitizer = Rails::Html::FullSanitizer.new
    # nil-safe
    text = sanitizer.sanitize(question.text.to_s)
    # remove Cambodia Only, Kenya Only, Tanzania Only and Ethiopia Only markers, allow optional surrounding asterisks or parentheses/brackets
    text = text.gsub(/(?:\*|\(|\[)?\s*(?:Cambodia|Kenya|Tanzania|Ethiopia)\s+Only(?:\*|\)|\])?/i, '')
    # replace newlines with space
    text = text.gsub(/\r\n|\r|\n/, ' ')
    # if starting text is . or ..., remove it
    text = text.sub(/\A(\.\.\.|\.)\s*/, '')
    # add space after period if missing
    text = text.gsub(/\.([^\s])/, '. \1')
    # normalize whitespace (squish requires ActiveSupport)
    text = text.squish
    # final trim
    text = text.strip
    # downcase all text
    text = text.downcase
    text
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
    # question.after_text_instruction&.text
  end

  def pop_up_instruction_text
    # question.pop_up_instruction&.text
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

  # Find the most similar InstrumentQuestion in the given instrument.
  # Returns the nearest InstrumentQuestion record (or nil) and sets
  # `neighbor_distance` on the returned record when available.
  #
  # Example:
  #   iq = InstrumentQuestion.find(1)
  #   other_instrument = Instrument.find(42)
  #   similar = iq.most_similar_in_instrument(other_instrument)
  #   similar.neighbor_distance # => distance value (if neighbor returns it)
  def most_similar_in_instrument(target_instrument, limit: 1, distance: 'cosine')
    return nil unless target_instrument && target_instrument.id

    # Ensure we have an embedding for this record
    unless embedding && embedding.is_a?(Array) && embedding.any?
      Rails.logger.warn "most_similar_in_instrument: no embedding for InstrumentQuestion id=#{id}"
      return nil
    end

    # Use the Neighbor gem API. There are two supported forms depending on
    # neighbor version; try to call the class-level nearest_neighbors and
    # filter by instrument_id. If that doesn't work, fall back to in-memory
    # similarity (slow).
    begin
      # Class method that accepts a vector and returns an AR relation
      rel = InstrumentQuestion.nearest_neighbors(:embedding, embedding, distance: distance)
      rel = rel.where(instrument_id: target_instrument.id)
      result = rel.first(limit)
      return result
    rescue NoMethodError, ArgumentError => e
      Rails.logger.info "neighbor fallback: #{e.class}: #{e.message}"
    end

    # Fallback: compute cosine similarity in Ruby across candidate rows
    candidates = InstrumentQuestion.where(instrument_id: target_instrument.id).where.not(embedding: nil)
    best = nil
    best_score = -Float::INFINITY
    candidates.find_each do |cand|
      next unless cand.embedding.is_a?(Array) && cand.embedding.any?
      # cosine similarity
      dot = embedding.zip(cand.embedding).map { |a, b| a.to_f * b.to_f }.sum
      mag_a = Math.sqrt(embedding.map { |v| v.to_f**2 }.sum)
      mag_b = Math.sqrt(cand.embedding.map { |v| v.to_f**2 }.sum)
      next if mag_a.zero? || mag_b.zero?
      score = dot / (mag_a * mag_b)
      if score > best_score
        best_score = score
        best = cand
      end
    end
    # attach neighbor_distance for consistency with neighbor results (higher = more similar for cosine)
    if best
      best.define_singleton_method(:neighbor_distance) { best_score }
    end
    best
  end

  def neighbor_combined_distance(neighbor)
    return nil unless neighbor && neighbor.embedding.is_a?(Array) && neighbor.embedding.any?
    return nil unless embedding && embedding.is_a?(Array) && embedding.any?
    # cosine similarity
    dot = embedding.zip(neighbor.embedding).map { |a, b| a.to_f * b.to_f }.sum
    mag_a = Math.sqrt(embedding.map { |v| v.to_f**2 }.sum)
    mag_b = Math.sqrt(neighbor.embedding.map { |v| v.to_f**2 }.sum)
    return nil if mag_a.zero? || mag_b.zero?
    score = dot / (mag_a * mag_b)
    1 - score
  end

  def neighbor_text_distance(neighbor)
    return nil unless neighbor && neighbor.embedding_qtext.is_a?(Array) && neighbor.embedding_qtext.any?
    return nil unless embedding_qtext && embedding_qtext.is_a?(Array) && embedding_qtext.any?
    # cosine similarity
    dot = embedding_qtext.zip(neighbor.embedding_qtext).map { |a, b| a.to_f * b.to_f }.sum
    mag_a = Math.sqrt(embedding_qtext.map { |v| v.to_f**2 }.sum)
    mag_b = Math.sqrt(neighbor.embedding_qtext.map { |v| v.to_f**2 }.sum)
    return nil if mag_a.zero? || mag_b.zero?
    score = dot / (mag_a * mag_b)
    1 - score
  end

  def neighbor_option_distance(neighbor)
    return nil unless neighbor && neighbor.embedding_otext.is_a?(Array) && neighbor.embedding_otext.any?
    return nil unless embedding_otext && embedding_otext.is_a?(Array) && embedding_otext.any?
    # cosine similarity
    dot = embedding_otext.zip(neighbor.embedding_otext).map { |a, b| a.to_f * b.to_f }.sum
    mag_a = Math.sqrt(embedding_otext.map { |v| v.to_f**2 }.sum)
    mag_b = Math.sqrt(neighbor.embedding_otext.map { |v| v.to_f**2 }.sum)
    return nil if mag_a.zero? || mag_b.zero?
    score = dot / (mag_a * mag_b)
    1 - score
  end

  def most_similar_in_instrument_text(target_instrument, limit: 1, distance: 'cosine')
    return nil unless target_instrument && target_instrument.id

    unless embedding_qtext && embedding_qtext.is_a?(Array) && embedding_qtext.any?
      Rails.logger.warn "most_similar_in_instrument_text: no embedding for InstrumentQuestion id=#{id}"
      return nil
    end

    begin
      rel = InstrumentQuestion.nearest_neighbors(:embedding_qtext, embedding_qtext, distance: distance)
      rel = rel.where(instrument_id: target_instrument.id)
      result = rel.first(limit)
      return result
    rescue NoMethodError, ArgumentError => e
      Rails.logger.info "neighbor fallback: #{e.class}: #{e.message}"
    end

    candidates = InstrumentQuestion.where(instrument_id: target_instrument.id).where.not(embedding_qtext: nil)
    best = nil
    best_score = -Float::INFINITY
    candidates.find_each do |cand|
      next unless cand.embedding_qtext.is_a?(Array) && cand.embedding_qtext.any?
      dot = embedding_qtext.zip(cand.embedding_qtext).map { |a, b| a.to_f * b.to_f }.sum
      mag_a = Math.sqrt(embedding_qtext.map { |v| v.to_f**2 }.sum)
      mag_b = Math.sqrt(cand.embedding_qtext.map { |v| v.to_f**2 }.sum)
      next if mag_a.zero? || mag_b.zero?
      score = dot / (mag_a * mag_b)
      if score > best_score
        best_score = score
        best = cand
      end
    end

    if best
      best.define_singleton_method(:neighbor_distance) { best_score }
    end
    best
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
