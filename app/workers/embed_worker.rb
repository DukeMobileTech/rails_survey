class EmbedWorker
  include Sidekiq::Worker

  def perform(instrument_id)
    instrument = Instrument.find instrument_id
    instrument.instrument_questions.find_each do |iq|
      iq.generate_embedding
    end
  end
end
