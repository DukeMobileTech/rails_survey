class CreateOptionScores < ActiveRecord::Migration[4.2]
  def change
    create_table :option_scores do |t|
      t.integer :score_unit_id
      t.integer :option_id
      t.float :value

      t.timestamps
    end
  end
end
