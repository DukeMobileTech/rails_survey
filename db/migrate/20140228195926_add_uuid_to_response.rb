class AddUuidToResponse < ActiveRecord::Migration
  def change
    add_column :responses, :uuid, :string
  end
end
