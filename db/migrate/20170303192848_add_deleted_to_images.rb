class AddDeletedToImages < ActiveRecord::Migration[4.2]
  def change
    add_column :images, :deleted_at, :datetime
    add_index :images, :deleted_at
  end
end
