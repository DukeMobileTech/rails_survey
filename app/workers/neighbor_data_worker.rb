class NeighborDataWorker
  include Sidekiq::Worker

  def perform(instrument_question_id)
    instrument_question = InstrumentQuestion.find_by(id: instrument_question_id)
    if instrument_question.nil?
      Rails.logger.warn("NeighborDataWorker: InstrumentQuestion with id #{instrument_question_id} not found")
      return
    end
    instrument_question.generate_neighbor_data
  end
end