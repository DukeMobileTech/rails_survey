class EnableVector < ActiveRecord::Migration[4.2]
  def change
    enable_extension 'vector'
  end
end
