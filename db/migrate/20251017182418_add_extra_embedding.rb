class AddExtraEmbedding < ActiveRecord::Migration[5.2]
  def change
    add_column :instrument_questions, :embedding_qtext, :vector, limit: 1536
    add_column :instrument_questions, :embedding_otext, :vector, limit: 1536
  end
end
