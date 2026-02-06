class AddClosestNeighborsByTextDistanceToInstrumentQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :instrument_questions, :neighbors_by_text_distance, :text
    add_column :instrument_questions, :neighbors_by_combined_distance, :text
  end
end
