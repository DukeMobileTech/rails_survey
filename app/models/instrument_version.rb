class InstrumentVersion
  attr_accessor :instrument, :version

  def method_missing(method, *args, &block)
    if Instrument.method_defined?(method)
      if @version
        @version.reify.send(method, *args, &block)
      else
        @instrument.send(method, *args, &block)
      end
    else
      super
    end
  end

  def self.build(params = {})
    instrument = Instrument.find(params[:instrument_id])
    version_number = params[:version_number].to_i
    instrument_version = InstrumentVersion.new
    instrument_version.instrument = instrument
    if instrument.current_version_number > version_number
      versions = Rails.cache.fetch("instrument_versions-#{instrument.id}", expires_in: 1.hour) do
        instrument.versions
      end
      instrument_version.version = Rails.cache.fetch("instrument_versions-#{instrument.id}-#{version_number}", expires_in: 1.hour) do
        versions[version_number]
      end
    end
    instrument_version
  end

  def questions
    return @instrument.questions unless @version
    return @questions if @questions
    questions = []
    @version.reify.questions.with_deleted.each do |question|
      versioned_question = versioned(question)
      next unless versioned_question
      questions << versioned_question
      options = options_for_question(versioned_question)
      versioned_question.define_singleton_method(:options) { options }
    end
    @questions = questions
  end

  def find_question_by(options = {})
    finder, value = options.first
    return @instrument.questions.send("find_by_#{finder}".to_sym, value) unless @version
    question = @version.reify.questions.send("find_by_#{finder}".to_sym, value)
    if question
      versioned_question = versioned(question)
      options = options_for_question(versioned_question)
      versioned_question.define_singleton_method(:options) { options }
      versioned_question
    end
  end

  def versioned(object)
    return object unless @version
    object.version_at(@version.created_at)
  end

  private

  def options_for_question(question)
    return [] unless question
    return question.options unless @version
    options = []
    question.options.with_deleted.each do |option|
      options << versioned(option) if versioned(option)
    end
    options
  end
end
