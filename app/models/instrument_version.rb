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
      instrument_version.version = instrument.versions[version_number]
    end
    instrument_version
  end
  
  def questions
    return @instrument.questions unless @version
    questions = []
    @version.reify.questions.with_deleted.each do |question|
      versioned_question = versioned(question)
      if versioned_question
        questions << versioned_question
        options = options_for_question(versioned_question)
        versioned_question.define_singleton_method(:options) { options }
      end
    end
    questions
  end

  def versioned(object)
    return object unless @version
    object.version_at(@version.created_at)
  end

  private
  def options_for_question(question)
    return question.options unless @version
    options = []
    question.options.with_deleted.each do |option|
      options << versioned(option) if versioned(option)
    end
    options
  end
end
