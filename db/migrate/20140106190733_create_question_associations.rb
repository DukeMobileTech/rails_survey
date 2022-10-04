class CreateQuestionAssociations < ActiveRecord::Migration[4.2]
  def change
    create_table :question_associations do |t|
      t.integer :instrument_version
      t.integer :question_version
      t.timestamps
    end
  end
end
