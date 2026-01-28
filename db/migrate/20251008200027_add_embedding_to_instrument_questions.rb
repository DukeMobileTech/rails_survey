class AddEmbeddingToInstrumentQuestions < ActiveRecord::Migration[4.2]
  def change
    add_column :instrument_questions, :embedding, :vector, limit: 1536
  end
end
